/*
Copyright © 2021 SpaceONE <spaceone-support@mz.co.kr>

*/
package cmd

import (
	"fmt"
	"io"
	"log"
	"net"
	"os"
	"os/exec"
	"strings"

	"github.com/pkg/errors"
	"github.com/spf13/cobra"
)

// installCmd represents the install command
var installCmd = &cobra.Command{
	Use:   "install",
	Short: "Install SpaceONE",
	Long:  `Install SpaceONE from EKS Cluster to SpaceONE`,
	Run: func(cmd *cobra.Command, args []string) {
		_setAwsCredentais()
		_setKubectlConfig()

		isMinimal, _ := cmd.Flags().GetBool("minimal")

		Build(isMinimal)
	},
}

func init() {
	rootCmd.AddCommand(installCmd)
	// Here you will define your flags and configuration settings.
	// installCmd.PersistentFlags().String("foo", "", "A help for foo")
	// installCmd.Flags().BoolP("toggle", "t", false, "Help message for toggle")

	installCmd.Flags().BoolP("minimal", "", false, "install minimal mode")
}

func Build(isMinimal bool) {
	log.Println("Start building SpaceONE")

	components := _getInstallComponents(isMinimal)

	// Generate tfvars from vars and gpg key before applying terraform
	for _, component := range components {
		err := _generateTfvars(component)
		if err != nil {
			panic(err)
		}

		if component == "secret" {
			if err := _generateGpgKey(); err != nil {
				panic(err)
			}
		}
	}

	// applying terraform
	for _, component := range components {
		_executeTerraform(component, "install")
	}

	if isMinimal {
		_setDomainForInternal()
	}

	log.Println("SpaceONE build complete")
}

func _getInstallComponents(isMinimal bool) []string {
	if isMinimal {
		os.Setenv("TF_VAR_minimal", "true")
		return []string{"eks", "controllers", "deployment", "initialization"}
	} else {
		os.Setenv("TF_VAR_standard", "true")
		return []string{"certificate", "eks", "controllers", "documentdb", "secret", "deployment", "initialization"}
	}
}

// TODO: find a simple way
func _setDomainForInternal() {
	consoleDomainName := _getNlbDomainNameFromService("console")
	consoleApiDomainName := _getNlbDomainNameFromService("console-api")
	monitoringWebhookDomainName := _getNlbDomainNameFromService("monitoring-rest")

	cmd := fmt.Sprintf("sed -i 's/console-api.example.com/%s/' ./data/helm/values/spaceone/minimal.yaml", consoleApiDomainName)
	_, err := exec.Command("bash", "-c", cmd).CombinedOutput()
	if err != nil {
		panic(errors.Wrap(err, "Failed to Update console-api domain"))
	}

	cmd = fmt.Sprintf("sed -i 's/monitoring-webhook.example.com/%s/' ./data/helm/values/spaceone/minimal.yaml", monitoringWebhookDomainName)
	_, err = exec.Command("bash", "-c", cmd).CombinedOutput()
	if err != nil {
		panic(errors.Wrap(err, "Failed to Update monitoring-webhook domain"))
	}

	/**
	* After set domain, spaceone and console pod should be update
	**/

	// Update configmap
	Upgrade()

	// To mount the updated configmap to console pod
	_restartConsolePod()

	ip := _getIpFromDomain(consoleDomainName)
	
	hostSetMsg := fmt.Sprintf(`
"****************************************************************************************" +

SpaceONE minimal set does not have a public domain. 

1. To access SpaceONE console, Add "%v spaceone.console-dev.com" to hosts file (etc. /etc/hosts)

2. Open a browser(http://spaceone.console-dev.com) and log in 

****************************************************************************************`,ip)

	log.Println(hostSetMsg)
}

func _getNlbDomainNameFromService(serviceName string) string {
	cmd := fmt.Sprintf("kubectl get svc %s -n spaceone --output=custom-columns=\"hostname:status.loadBalancer.ingress[*].hostname\" | tail -n1", serviceName)
	output, err := exec.Command("bash", "-c", cmd).Output()
	if err != nil {
		panic(errors.Wrap(err, "Failed to get console domain name"))
	}

	domainName := strings.TrimSuffix(string(output), "\n")

	return domainName
}

func _restartConsolePod() {
	log.Println("restart console pod")

	deleteConsolePod := "kubectl delete pod -l spaceone.service=console -n spaceone"
	cmd := exec.Command("bash", "-c", deleteConsolePod)

	if err := cmd.Start(); err != nil {
		panic(errors.Wrap(err, "Failed to execute delete console pods command"))
	}

	if err := cmd.Wait(); err != nil {
		panic(errors.Wrap(err, "Failed to delete console pods"))
	}
}

func _getIpFromDomain(domain string) string {
	ips, _ := net.LookupHost(domain)
	if len(ips) < 0 {
		msg := fmt.Sprintf("There's nothing on the ips %v",ips)
		panic(msg)
	}
	firstIp := ips[0]

	return firstIp
}

//TODO: Using gpg client
func _generateGpgKey() error {
	log.Printf("Generate gpg key")

	gpgConfigPath := "/tmp/gpg_config"
	gpgConfig, err := os.Create(gpgConfigPath)
	if err != nil {
		return errors.Wrap(err, "Failed to Create gpg config file")
	}
	defer gpgConfig.Close()

	configurations := []byte(`%echo Generating a key type RSA
Key-Type: RSA
Subkey-Type: RSA
Name-Real: spaceone
Name-Comment: Encrypt AWS Secrets
Name-Email: gpg@spaceone.org
Expire-Date: 2
Passphrase: spaceone
%commit
%echo done`)
	_, err = io.WriteString(gpgConfig, string(configurations))
	if err != nil {
		return errors.Wrap(err, "Failed to Write gpg config to file")
	}

	err = exec.Command("gpg", "--no-tty", "--batch", "--gen-key", gpgConfigPath).Run()
	if err != nil {
		return errors.Wrap(err, "gpg key generation command error")
	}

	err = exec.Command("gpg", "--output", "./module/secret/gpg/public-key-binary.gpg", "--export", "gpg@spaceone.org").Run()
	if err != nil {
		return errors.Wrap(err, "Failed to export gpg key")
	}

	return nil
}

func _generateTfvars(component string) error {
	src := fmt.Sprintf("./vars/%v.conf", component)
	dst := fmt.Sprintf("./module/%v/%v.auto.tfvars", component, component)

	if component != "secret" && component != "controllers" {
		log.Printf("Generate %s.auto.tfvars", component)
		err := _fileCopy(src, dst)
		if err != nil {
			return errors.Wrap(err, "Failed to generate tfvars")
		}
	}

	return nil
}
