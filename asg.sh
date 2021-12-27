#!/bin/bash

DIR=.terraform
TF=${DIR}/main.tf
STATE=${DIR}/terraform.tfstate
SERV=$(which terraform)

if [ -z "${SERV}" ]; then
    echo -n "Terraform not found. Do you want to install it? [y/n] "
    read -r REPLY
    if [ ${REPLY} == "y" ]; then
        ARCH=$(dpkg --print-architecture)
        if [ "$ARCH" == "arm64" ]; then
            sudo apt-get update &> /dev/null
            sudo apt-get install -y unzip &> /dev/null
            wget https://releases.hashicorp.com/terraform/1.1.2/terraform_1.1.2_linux_arm64.zip &> /dev/null
            unzip terraform_1.1.2_linux_arm64.zip &> /dev/null
            rm -rf terraform_1.1.2_linux_arm64.zip &> /dev/null
            sudo mv terraform /usr/local/bin/
            VER=$(terraform -v | head -n 1 | cut -d ' ' -f 2)
            echo -e "\e[0;32mTerraform installed: ${VER}\e[0m"
        elif [ "$ARCH" == "amd64" ]
        then
            sudo apt-get update &> /dev/null
            sudo apt-get install -y unzip &> /dev/null
            wget https://releases.hashicorp.com/terraform/1.1.2/terraform_1.1.2_linux_amd64.zip &> /dev/null
            unzip terraform_1.1.2_linux_amd64.zip &> /dev/null
            rm -rf terraform_1.1.2_linux_amd64.zip &> /dev/null
            sudo mv terraform /usr/local/bin/
            VER=$(terraform -v | head -n 1 | cut -d ' ' -f 2)
            echo -e "Terraform installed: ${VER}"
        else
            echo -e "Unsupported architecture: ${ARCH}"
        fi
    else
        echo -e "Need to install terraform.\nExiting..."
        exit 1
    fi
else
    VER=$(terraform -v | head -n 1 | cut -d ' ' -f 2)
    echo -e "Terraform found: ${VER}"
fi

while true;
do
    while true;
    do
        echo -en "Enter your AWS ACCESS KEY: "
        read AWS_ACCESS_KEY
        if [ -z $AWS_ACCESS_KEY ]
        then
            echo -e "\nPlease enter your Access Key."
            continue
        fi
        break
    done
    while true;
    do
        echo -en "Enter your AWS SECRET KEY: "
        read AWS_SECRET_KEY
        if [ -z $AWS_SECRET_KEY ]
        then
            echo -e "\nPlease enter your Secret Key."
            continue
        fi
        break
    done
    while true;
    do
        echo -en "Enter your AWS Region: "
        read AWS_REGION
        if [ -z $AWS_REGION ]
        then
            echo -e "\nPlease enter your AWS Region."
            continue
        fi
        break
    done
    while true;
    do
        echo -en "Enter your Project Name: "
        read AWS_PROJECT_NAME
        if [ -z $AWS_PROJECT_NAME ]
        then
            echo -e "\nPlease enter your Project Name."
            continue
        fi
        break
    done
    break
done

terraform -chdir="$DIR" init > /dev/null
if [[ -a $STATE ]]
then
        TF_RUN=$(terraform -chdir="$DIR" show)
        EXIST=$(cat $DIR/terraform.tfstate | grep -m1 "value" | xargs | cut -d " " -f 2 | cut -d "," -f 1)
        if [[ "$AWS_PROJECT_NAME" == "$EXIST" ]]
        then
                if [[ -n $TF_RUN ]]
                then
                        echo -en "\nDo you want to destroy your existing VPC? (y/n): "
                        read ANSWER
                        case $ANSWER in
                            y)
                                TF_VAR_access_key=$AWS_ACCESS_KEY TF_VAR_secret_key=$AWS_SECRET_KEY TF_VAR_aws_region=$AWS_REGION TF_VAR_project_name=$AWS_PROJECT_NAME terraform -chdir="$DIR" destroy -auto-approve
                                rm -rf $DIR/terraform.tfstate*
                                ;;
                            n)
                                exit
                                ;;
                            *)
                                exit
                                ;;
                        esac
                fi
        else
                echo -e "\nPlease enter a valid Project Name."
                exit
        fi
else
        TF_VAR_access_key=$AWS_ACCESS_KEY TF_VAR_secret_key=$AWS_SECRET_KEY TF_VAR_aws_region=$AWS_REGION TF_VAR_project_name=$AWS_PROJECT_NAME terraform -chdir="$DIR" apply -auto-approve
fi