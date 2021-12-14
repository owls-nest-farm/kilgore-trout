# kilgore-trout

This web service relies upon a [GitHub webhook] to send it data when a subscribed event has been triggered.  In the case of this demo, it will forward data about repositories.

The service does the following things:

- Listens for [`repository` events] and acts upon `created` actions.
- Creates branch protections for the "master" branch of the newly-created repository.
- Creates an issue in the new repository, detailing the protections and creating a mention.

There are two ways to use the Go web service:

- [Development](#development)
    + [Setup: SSH Remote Port Forwarding](#setup-ssh-remote-port-forwarding)
    + [Setup: `ngrok`](#setup-ngrok)
- [Staging and Production](#staging-and-production)

Let's look at each of these in turn.

---

## Development

The development environment uses [Vagrant] to create and provision a virtual machine.  It is the only dependency.

Vagrant was chosen because it is a well-known tool common in many development environments.  In addition, it supports many provisioners such as [Ansible] and simple shell scripts.  The latter was used for this demo.

Both solutions use tunneling to forward the request from Github to our local web service.  It facilitates local development.

Cool!

### Setup: SSH Remote Port Forwarding

> In order for SSH remote port forwarding to work, it is necessary to have administrative access to the remote machine on the public Internet.
>
> Note that anytime you open ports on a public server it is a security risk, which is why this feature is off by default.  Buyer beware!
>
> On the remote machine:
>
> 1. Allow the forwarding in `/etc/ssh/sshd_config`.
>
>    Change `GatewayPorts no` to `GatewayPorts yes`:
>
>        sudo sed -i 's/.*GatewayPorts no.*/GatewayPorts yes/' /etc/ssh/sshd_config
>
> 1. Restart the server.
>
>        sudo systemctl restart sshd

1. Create the tunnel, start Vagrant and log in.

    - Set the GitHub token in the `GITHUB_TOKEN` environment variable.
    - Set the location of the public server that GitHub will send the Webhook data as `WEBHOOK_URL`.

          GITHUB_TOKEN=xxxxxxxxxxxxxxx \
          WEBHOOK_URL=https://www.example.com:4141 \
          ./start.sh

    > Make sure your `GITHUB_TOKEN` is in your current environment.  Vagrant will pass this through to the `.bashrc` run command file that is sourced whenever logging into the virtual machine.

1. Create the webhook and start the Go server.

        URL="$WEBHOOK_URL" ./setup.sh

    > Note that when the server is killed, the webhook is automatically removed.

1. When finished, exit the VM and tear it and the SSH tunnel down by running the destroy script on the host.

        ./destroy.sh

### Setup: `ngrok`

This is a bit more work to setup, but it's worth adding for completeness.

Why `ngrok`?  Well, you may not have root access to a machine and thus no way to configure the SSH server.

How does `ngrok` work?  `ngrok` will create an endpoint in the public Internet which will be used by our GitHub webhook.  GitHub doesn't care what's listening on the port it sends the `tcp` connection to, as long as it's reachable.  From there, `ngrok` takes over and forwards/tunnels the request to our development environment on our local machine.  The only requirement is that the port we gave `ngrok` will creating the tunnel is open.

1. Start Vagrant.

        GITHUB_TOKEN=xxxxxxxxxxxxxxx \
            ./start.sh

    > Make sure your `GITHUB_TOKEN` is in your current environment.  Vagrant will pass this through to the `.bashrc` run command file that is sourced whenever logging into the virtual machine.

1. Start `ngrok` in the VM.

        ngrok http 4141

1. Copy the `https` URL of the `ngrok` output to your clipboard.

    Unfortunately, it's not easy to use `ngrok` in a Unix pipeline or shell script.  For instance, it would be nice if there were a way to run `ngrok` and have it report a specified URL to `stdout`, but it doesn't allow for that.  It does look like it's possible to specify a URL, but not in the free version, so that's not an option.

    So, it's gross to have to manually copy the URL, but so it goes.  My suggestion would be to use the SSH remote port forwarding method, if possible.

1. Open another window session on the host machine (or use [`screen`] or [`tmux`] another terminal multiplexer).

    If not using `screen` or `tmux`, export the `GITHUB_TOKEN` and log into the new window session.

        export GITHUB_TOKEN=xxxxxxxxxxxxxxx
        vagrant ssh

1. Create the webhook and start the Go server in the VM.

        URL={the_copied_ngrok_url_from_step_3} ./setup.sh

    > Note that when the server is killed, the webhook is automatically removed.

1. When finished, exit the VM and tear it down.

        vagrant destroy

## Staging and Production

There are, of course, many ways in which the web service could be deployed to a staging and production server(s).  Here are some ways that I've done it in the past:

- Shell script

    + Secure copy (`scp`) the script to the server
    + Remote execute an SSH command to run it
    + For example, I use [a simple shell script] to build and deploy my own website.

- Jenkins

    + Use either declarative or scripted pipeline
    + Create an instance in the cloud or server that you own (preferred) as a build agent
    + Deploy the image

- Terraform

    + Create the server instance in the cloud
    + Provision using [`Chef`]
    + Pull the image

## Considerations

- Ease of use
- The less dependencies the better
- Use foundational technologies when possible

## Attribution

- This web service was built using [Google's Go library] for interacting with the [GitHub REST API].

[GitHub webhook]: https://docs.github.com/en/github-ae@latest/developers/webhooks-and-events/webhooks
[`repository` events]: https://docs.github.com/en/github-ae@latest/developers/webhooks-and-events/webhooks/webhook-events-and-payloads#repository
[Vagrant]: https://www.vagrantup.com/
[Ansible]: https://www.ansible.com/
[`screen`]: https://www.man7.org/linux/man-pages/man1/screen.1.html
[`tmux`]: https://github.com/tmux/tmux
[Pull an image from Docker Hub]: https://hub.docker.com/
[Docker Engine]: https://docs.docker.com/engine/
[`ngrok`]: https://ngrok.com/
[Google's Go library]: https://github.com/google/go-github
[GitHub REST API]: https://docs.github.com/en/github-ae@latest/rest
[a simple shell script]: https://github.com/btoll/benjamintoll.com/blob/master/build_and_deploy.sh
[`Chef`]: https://docs.chef.io/ruby/

