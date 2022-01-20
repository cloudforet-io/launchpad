/*
Copyright © 2021 SpaceONE <spaceone-support@mz.co.kr>

*/
package cmd

import (
	"fmt"
	"io/ioutil"
	"log"
	"os/exec"
	"time"

	"github.com/briandowns/spinner"
	"github.com/pkg/errors"
	"github.com/spf13/cobra"
)

// upgradeCmd represents the upgrade command
var upgradeCmd = &cobra.Command{
	Use:   "upgrade",
	Short: "Upgrade SpaceONE",
	Long: `Upgrade SpaceONE
If there is a new release, use the --update-repo option.

SpaceONE release example:
https://github.com/spaceone-dev/charts`,
	Run: func(cmd *cobra.Command, args []string) {
		_setAwsCredentais()
		_setKubectlConfig()

		isRepoUpdate, err := cmd.Flags().GetBool("update-repo")
		if err != nil {
			panic(errors.Wrap(err, "Failed to get command flag"))
		}

		if isRepoUpdate {
			_updateHelmRepo()
		}

		upgrade()
	},
}

func init() {
	rootCmd.AddCommand(upgradeCmd)

	upgradeCmd.Flags().BoolP("update-repo", "", false, "Update helm repository before upgrade helm chart")
}

func upgrade() {
	log.Println("Upgrade SpaceONE")
	s := spinner.New(spinner.CharSets[26], 100*time.Millisecond)
	s.Prefix = "[upgrade] spaceone"
	s.FinalMSG = "ok\n"

	s.Start()
	_upgradeHelmRelease()
	s.Stop()

	log.Println("SpaceONE upgrade complete")
}

func _upgradeHelmRelease() {
	options := _getHelmCmdOptions()
	cmd := exec.Command(
		"helm",
		options...,
	)

	stdoutStderr, err := cmd.CombinedOutput()
	if err != nil {
		panic(errors.Wrap(err, string(stdoutStderr)))
	}
}

func _getHelmCmdOptions() []string {
	helmValueFiles := _getHelmValues()
	repositoryCachePath := "./data/helm/cache/repository"
	repositoryConfigPath := "./data/helm/config/repositories.yaml"

	options := []string{
		"upgrade",
		"spaceone",
		"spaceone/spaceone",
		"-n", "spaceone",
	}

	for _, helmValue := range helmValueFiles {
		options = append(options, "-f")
		options = append(options, helmValue)
	}

	options = append(options, "--repository-cache")
	options = append(options, repositoryCachePath)

	options = append(options, "--repository-config")
	options = append(options, repositoryConfigPath)

	return options
}

func _getHelmValues() []string {
	var helmValues []string
	ignoreFileList := []string{".gitkeep"}

	files, err := ioutil.ReadDir("./data/helm/values/spaceone/")
	if err != nil {
		panic(errors.Wrap(err, "ReadDir Error"))
	}

	for _, file := range files {
		valueFileName := file.Name()
		if !_checkContainFile(ignoreFileList, valueFileName) {
			fullPath := fmt.Sprintf("./data/helm/values/spaceone/%s", valueFileName)
			helmValues = append(helmValues, fullPath)
		}
	}

	if len(helmValues) < 1 {
		panic("helm value file does not exist!")
	}

	return helmValues
}

// TODO: Using go helm client
func _updateHelmRepo() {
	repositoryCachePath := "./data/helm/cache/repository"
	repositoryConfigPath := "./data/helm/config/repositories.yaml"

	args := []string{
		"repo",
		"update",
		"--repository-cache", repositoryCachePath,
		"--repository-config", repositoryConfigPath,
	}

	cmd := exec.Command("helm", args...)
	stdoutStderr, err := cmd.CombinedOutput()
	if err != nil {
		panic(errors.Wrap(err, string(stdoutStderr)))
	}
}
