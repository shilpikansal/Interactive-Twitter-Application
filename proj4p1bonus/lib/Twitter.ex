defmodule Mix.Tasks.Twitter do


def main() do
  {:ok, engine} = Engine.start_link(["hi"])
end

def registration(numUsers) do
  user_pids = create_user_pids(numUsers)
  Process.sleep(100)
  :ets.new(:allUserPids, [:set, :public, :named_table])
  :ets.insert(:allUserPids,{"allPids",user_pids})
  numberRegisteredUsers = Engine.getUserCount

  numberRegisteredUsers
end

def subscriptions(numUsers,numTweets,regularUsers) do


sCount = numTweets
[{_,user_pids}]=:ets.lookup(:allUserPids,"allPids")

pid_id_map = create_pid_id_map(user_pids,numUsers)
addSubscribers(numUsers,user_pids,pid_id_map,sCount,regularUsers)

result = Engine.verifyFollowers(numUsers,sCount,user_pids,regularUsers)

result
end

def tweets(numUsers,numTweets,regularUsers) do

sCount = numTweets
[{_,user_pids}]=:ets.lookup(:allUserPids,"allPids")
startTweets(numUsers,numTweets,user_pids,regularUsers)


result = Engine.verifyTweets(numUsers,sCount,user_pids,regularUsers)

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
result = Engine.verifyHashTags
result
end

def create_user_pids(numUsers) do

  Enum.map(0..numUsers-1, fn val -> {:ok, user} = User.start_link([val])
                                    user
                                    end)
end

def addSubscribers(numUsers,user_pids,pid_id_map,sCount,regularUsers) do
  Enum.each(0..regularUsers-1, fn userNum ->
                  Enum.each(1..sCount, fn tcount -> user = Enum.at(user_pids,userNum)
                                                    tempUserPids=List.delete(user_pids,user)
                                                    len = length(tempUserPids)
                                                    sNum = :rand.uniform(len-1)
                                                    sId = Enum.at(tempUserPids,sNum)
                                                  User.subscribe(user,sId)
                      end)
                      r_string = "2"
                  end)


  Enum.each(regularUsers..numUsers-1, fn userNum ->
                  Enum.each(1..sCount+1, fn tcount -> user = Enum.at(user_pids,userNum)
                                                    tempUserPids=List.delete(user_pids,user)
                                                    len = length(tempUserPids)
                                                    sNum = :rand.uniform(len-1)
                                                    sId = Enum.at(tempUserPids,sNum)
                                                    User.subscribe(user,sId)
                      end)
                      r_string = "2"
                  end)

end


def startTweets(numUsers,numTweets,user_pids,regularUsers) do

Enum.each(0..regularUsers-1, fn userNum ->
               Enum.each(1..numTweets, fn tcount ->   value = create_tweet(userNum,numUsers,tcount)
                                                      User.sendTweet(Enum.at(user_pids,userNum),value,user_pids)
                        end)
                end)

Enum.each(regularUsers..numUsers-1, fn userNum ->
               Enum.each(1..numTweets+1, fn tcount ->   value = create_tweet(userNum,numUsers,tcount)
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
