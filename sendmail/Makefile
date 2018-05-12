default: build

fix:
	goimports -l -w .
	gofmt -l -w -s .

build: fix
	go build -v -ldflags '-s -w' .

all:
	GOOS=windows GOARCH=amd64 make build && mv sendmail.exe sendmail-x64.exe
	GOOS=windows GOARCH=386 make build && mv sendmail.exe sendmail-x86.exe

	GOOS=linux GOARCH=amd64 make build && mv sendmail sendmail-linux-x64
	GOOS=linux GOARCH=386 make build && mv sendmail sendmail-linux-x86

deps:
	go get golang.org/x/tools/cmd/goimports
