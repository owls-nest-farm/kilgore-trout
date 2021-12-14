package main

import (
	"encoding/json"
	"fmt"

	"github.com/google/go-github/v41/github"
)

type WebService struct {
	Action  string
	Owner   string
	Repo    string
	Branch  string
	Private bool
	False   bool
	True    bool
}

func NewWebService(payload github.WebHookPayload) WebService {
	var action string
	if payload.Action != nil {
		action = *payload.Action
	}

	var owner string
	if payload.Organization.Login != nil {
		owner = *payload.Organization.Login
	}

	var repo string
	if payload.Repo.Name != nil {
		repo = *payload.Repo.Name
	}

	var defaultBranch string
	if payload.Repo.DefaultBranch != nil {
		defaultBranch = *payload.Repo.DefaultBranch
	}

	var isPrivate bool
	if payload.Repo.Private != nil {
		isPrivate = *payload.Repo.Private
	}

	return WebService{
		Action:  action,
		Owner:   owner,
		Repo:    repo,
		Branch:  defaultBranch,
		Private: isPrivate,
		False:   false,
		True:    true,
	}
}

func (w *WebService) CreateIssue(client *github.Client) (*github.Issue, *github.Response, error) {
	marshaled, err := w.StringifyBranchProtections(client)
	if err != nil {
		fmt.Println(err)
		panic(err)
	}

	title := "Set Branch Protections"
	assignee := "btoll"
	marshaledWithMention := fmt.Sprintf("@%s\n\n%s", assignee, marshaled)
	ireq := github.IssueRequest{
		Title:    &title,
		Body:     &marshaledWithMention,
		Assignee: &assignee,
	}

	return client.Issues.Create(getContext(), w.Owner, w.Repo, &ireq)
}

func (w *WebService) CreateRepository() []byte {
	var info string

	if w.Private {
		info = "[WARNING] This web service does not support branch protection for private repositories.  Upgrade to GitHub Pro or make this repository public to enable this feature."
		fmt.Println(info)
		return []byte(info)
	}

	// Can't depend on branch name because the github UI allows for repos to be created without a branch!
	// So, let's just look up the branch created when the repo is created!
	client := getClient()

	branches, _, err := client.Repositories.ListBranches(getContext(), w.Owner, w.Repo, &github.BranchListOptions{})
	if err != nil {
		fmt.Println(err)
		panic(err)
	}

	if len(branches) == 0 {
		info = fmt.Sprintf("[INFO] The repository `%s` was created but there are no branches to protect.", w.Repo)
		fmt.Println(info)
	} else {
		var userBranch string
		var protected bool

		if branches[0].Name != nil {
			userBranch = *branches[0].Name
		}

		if branches[0].Protected != nil {
			protected = *branches[0].Protected
		}

		if userBranch != w.Branch {
			info = fmt.Sprintf("[WARNING] The default branch name `%s` does not match the user-provided branch name `%s`.", w.Branch, userBranch)
			fmt.Println(info)
			w.Branch = userBranch
		}

		if !protected {
			_, _, err := w.SetBranchProtections(client)
			if err != nil {
				fmt.Println(err)
				panic(err)
			}
			info = fmt.Sprintf("[SUCCESS] Set branch protections on branch `%s`.", w.Branch)
			fmt.Println(info)

			_, _, err = w.CreateIssue(client)
			if err != nil {
				fmt.Println(err)
				panic(err)
			}
			info = fmt.Sprintf("[SUCCESS] Created issue on repository `%s`.", w.Repo)
			fmt.Println(info)
		} else {
			info = fmt.Sprintf("[INFO] The branch `%s` in repository `%s` is already protected, there is nothing to do here!", w.Branch, w.Repo)
			fmt.Println(info)
		}
	}

	return []byte(info)
}

func (w *WebService) SetBranchProtections(client *github.Client) (*github.Protection, *github.Response, error) {
	preq := github.ProtectionRequest{
		RequireLinearHistory:           &w.True,
		RequiredConversationResolution: &w.True,
		AllowForcePushes:               &w.False,
		AllowDeletions:                 &w.False,
		RequiredPullRequestReviews: &github.PullRequestReviewsEnforcementRequest{
			DismissStaleReviews:          true,
			RequireCodeOwnerReviews:      true,
			RequiredApprovingReviewCount: 5,
			DismissalRestrictionsRequest: &github.DismissalRestrictionsRequest{
				Teams: &[]string{"Security", "SRE"},
			},
		},
	}

	return client.Repositories.UpdateBranchProtection(getContext(), w.Owner, w.Repo, w.Branch, &preq)
}

func (w *WebService) StringifyBranchProtections(client *github.Client) (string, error) {
	var marshaled []byte

	protection, _, err := client.Repositories.GetBranchProtection(getContext(), w.Owner, w.Repo, w.Branch)

	if err == nil {
		marshaled, err = json.MarshalIndent(protection, "", "    ")
	}

	fmt.Println(string(marshaled))

	return string(marshaled), err
}
