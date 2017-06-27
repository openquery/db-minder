#
# I had a code green from all 4 servers
# Then I got a code red from 2 servers in the same data centre.
# So now I am code red.
# I ask for health of other data centre
# If no response in 2 seconds, I go ahead

# I record the last_committed at the time of the event. This will be used to see if we missed any transactions.
