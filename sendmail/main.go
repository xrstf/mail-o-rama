package main

import (
	"fmt"
	"os"
	"os/exec"

	ini "gopkg.in/ini.v1"
)

func main() {
	// first try to read the container name from an environment variable
	container := os.Getenv("MAILORAMA_CONTAINER")

	// load configuration from ini file
	if len(container) == 0 {
		cfg, err := ini.Load("/etc/mail-o-rama/sendmail.ini")
		if err != nil {
			fmt.Printf("Fail to read config file: %v", err)
			os.Exit(1)
		}

		container = cfg.Section("").Key("container").String()
	}

	// construct arguments to docker and then append args given to us from the caller
	args := []string{"exec", "-i", container, "sendmail"}
	args = append(args, os.Args[1:]...)

	// prepare docker process
	process := exec.Command("docker", args...)

	process.Stdin = os.Stdin
	process.Stdout = os.Stdout
	process.Stderr = os.Stderr

	// fire
	if process.Run() != nil {
		os.Exit(1)
	}
}
