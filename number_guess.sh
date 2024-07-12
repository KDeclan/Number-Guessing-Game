#!/bin/bash
PSQL="psql --username=freecodecamp --dbname=number_guess -t --no-align -c"

is_integer() {
  [[ "$1" =~ ^-?[0-9]+$ ]]
}

introduction() {
  echo "Enter your username:"
  read user_name

  # Check if the user exists in the database
  user_id=$($PSQL "SELECT user_id FROM users WHERE username = '$user_name'")
  
  if [[ -z $user_id ]]; then
    # If the user does not exist, add them to the database
    insert_user=$($PSQL "INSERT INTO users(username) VALUES('$user_name')")
    user_id=$($PSQL "SELECT user_id FROM users WHERE username = '$user_name'")
    echo -e "\nWelcome, $user_name! It looks like this is your first time here." 
  else
    # If the user exists, retrieve and display their stats
    user_stats=$($PSQL "SELECT games_played, best_game FROM users WHERE user_id = $user_id")
    IFS='|' read games_played best_game <<< "$user_stats"
    echo -e "\nWelcome back, $user_name! You have played $games_played games, and your best game took $best_game guesses."
  fi

  number_guess_game "$user_name" "$user_id"
}

number_guess_game() {
  user_name=$1
  user_id=$2
  # Generate a random number between 1 and 1000
  secret_number=$($PSQL "SELECT FLOOR(RANDOM() * 1000 + 1);")
  num_guesses=0
  
  echo -e "\nGuess the secret number between 1 and 1000:"

  while true; do
    read user_answer
    num_guesses=$((num_guesses + 1))

    # Check if the input is an integer
    if ! is_integer "$user_answer"; then
      echo -e "\nThat is not an integer, guess again:"
      continue
    fi

    # Convert user input to integer
    user_answer=$(($user_answer))

    # Check if the guess is correct
    if (( user_answer < secret_number )); then
      echo -e "\nIt's higher than that, guess again:"
    elif (( user_answer > secret_number )); then
      echo -e "\nIt's lower than that, guess again:"
    else
      echo -e You guessed it in $num_guesses tries. The secret number was $secret_number. Nice job!
      break
    fi
  done

  # Update games played and best game stats in the database
  games_played=$($PSQL "SELECT games_played FROM users WHERE user_id = $user_id")
  best_game=$($PSQL "SELECT best_game FROM users WHERE user_id = $user_id")

  new_games_played=$((games_played + 1))

  if [[ $best_game -eq 0 || $num_guesses -lt $best_game ]]; then
    update_user_result=$($PSQL "UPDATE users SET games_played = $new_games_played, best_game = $num_guesses WHERE user_id = $user_id")
  else
    update_user_result=$($PSQL "UPDATE users SET games_played = $new_games_played WHERE user_id = $user_id")
  fi
}

introduction
