package main

import (
	"context"
	"encoding/json"
	"flag"
	"fmt"
	"io/ioutil"
	"net/http"
	"os"

	"github.com/google/go-github/v41/github"
	"golang.org/x/oauth2"
)

func getClient() *github.Client {
	tc := getOAuthClient()
	return github.NewClient(tc)
}

var ctx context.Context
var singleContext *bool

func getContext() context.Context {
	if singleContext == nil {
		ctx = context.Background()
		b := true
		singleContext = &b
	}
	return ctx
}

func getOAuthClient() *http.Client {
	ts := oauth2.StaticTokenSource(
		&oauth2.Token{AccessToken: os.Getenv("GITHUB_TOKEN")},
	)
	return oauth2.NewClient(getContext(), ts)
}

func events(w http.ResponseWriter, r *http.Request) {
	data, err := ioutil.ReadAll(r.Body)
	if err != nil {
		panic(err)
	}
	defer r.Body.Close()

	var payload github.WebHookPayload
	if err = json.Unmarshal(data, &payload); err != nil {
		panic(err)
	}

	service := NewWebService(payload)

	if service.Action == "created" {
		info := service.CreateRepository()
		w.Write(info)
	}
}

func main() {
	port := flag.String("port", "80", "Port on which the Go server listens. Defaults to 80.")
	flag.Parse()

	http.HandleFunc("/events", events)
	if err := http.ListenAndServe(fmt.Sprintf(":%s", *port), nil); err != nil {
		panic(err)
	}
}
