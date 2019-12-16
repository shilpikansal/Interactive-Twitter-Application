defmodule Mix.Tasks.Twitter do

def main() do
  {:ok, engine} = Engine.start_link(["hi"])
end

def registration(numUsers) do
  user_pids = create_user_pids(numUsers)
  Process.sleep(100)
  :ets.new(:allUserPids, [:set, :public, :named_table])
  :ets.insert(:allUserPids,{"allPids",user_pids})
  #Engine.printusercount(numUsers)
  numberRegisteredUsers = Engine.getUserCount

  numberRegisteredUsers
end

def subscriptions(numUsers,numTweets) do

sCount = numTweets
[{_,user_pids}]=:ets.lookup(:allUserPids,"allPids")

pid_id_map = create_pid_id_map(user_pids,numUsers)
addSubscribers(numUsers,user_pids,pid_id_map,sCount)
#Engine.printfollowers(user_pids,numUsers)
result = Engine.verifyFollowers(numUsers,sCount,user_pids)

result
end

def tweets(numUsers,numTweets) do

sCount = numTweets
[{_,user_pids}]=:ets.lookup(:allUserPids,"allPids")
startTweets(numUsers,numTweets,user_pids)
#Engine.printTweets(user_pids,numUsers)

result = Engine.verifyTweets(numUsers,sCount,user_pids)

result
end

def reTweetsTestCase() do

  result = Engine.verifyRetweets
  result
end

def mentionsTestCase() do

  result = Engine.verifyMentions
  result
end

def hashTags() do
#Engine.printHashTags()
result = Engine.verifyHashTags
result
end

def allTestCases(numUsers,numTweets) do
#ExUnit.start()
#test ""
sCount = numTweets
[{_,user_pids}]=:ets.lookup(:allUserPids,"allPids")

numberRegisteredUsers = Engine.getUserCount
if(numberRegisteredUsers == numUsers ) do
  IO.puts "Registration test case passed"
else
  IO.puts "Registration test case failed"
end

result = Engine.verifyTweets(numUsers,numTweets,user_pids)
IO.puts("#{result}")

result = Engine.verifyFollowers(numUsers,sCount,user_pids)
IO.puts("#{result}")

result = Engine.verifyRetweets
if(result>=1) do
  IO.puts("Retweets test case passed")
else
  IO.puts("Retweets test case failed")
end

result = Engine.verifyHashTags
expected = numUsers * numTweets

  if(result == expected) do
    IO.puts("HashTags test case passed")
  else
    IO.puts("HashTags test case failed")
end
end

def create_user_pids(numUsers) do

  Enum.map(0..numUsers-1, fn val -> {:ok, user} = User.start_link([val])
                                    user
                                    end)
end

def addSubscribers(numUsers,user_pids,pid_id_map,sCount) do
  Enum.each(0..numUsers-1, fn userNum ->
                  Enum.each(1..sCount, fn tcount -> user = Enum.at(user_pids,userNum)
                                                    tempUserPids=List.delete(user_pids,user)
                                                    len = length(tempUserPids)
                                                    sNum = :rand.uniform(len-1)
                                                    sId = Enum.at(tempUserPids,sNum)
                                                  User.subscribe(user,sId)
                      end)
                      r_string = "2"
                  end)

end


def startTweets(numUsers,numTweets,user_pids) do

Enum.each(0..numUsers-1, fn userNum ->
               Enum.each(1..numTweets, fn tcount ->   value = create_tweet(userNum,numUsers,tcount)
                                                      User.sendTweet(Enum.at(user_pids,userNum),value,user_pids)
                        end)
                end)
end

def create_tweet(userNum,numUsers,tcount) do
  hashTag = "#COP5615isgreat"
  tagUserNum = :rand.uniform(numUsers) - 1
  userTag = "@" <> Integer.to_string(tagUserNum)
  #userTag = Integer.to_string(UserTag)
  #val = "This is random string"
  val = "This is tweet number #{tcount} by user number  #{userNum} with hashTag #{hashTag} tagging usernumber #{userTag}"
  val
end

def create_id_pid_map(user_pids,numUsers) do

  Enum.reduce(0..numUsers-1, %{}, fn (i, acc) ->
          Map.put(acc,i,Enum.at(user_pids,i))
          end)
end

def create_pid_id_map(user_pids,numUsers) do

  Enum.reduce(0..numUsers-1, %{}, fn (i, acc) ->
          Map.put(acc,Enum.at(user_pids,i),i)
          end)
end

end
