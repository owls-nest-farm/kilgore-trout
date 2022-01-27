FROM golang:1.17-bullseye

RUN useradd --create-home --home-dir /home/test test

USER test

WORKDIR /home/test

COPY go.mod go.sum ./

RUN go mod download

COPY main.go ./

RUN go build -o set_branch_protections

ENV USER test

ENTRYPOINT ["./set_branch_protections"]

