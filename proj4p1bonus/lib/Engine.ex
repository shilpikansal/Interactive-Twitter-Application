defmodule Engine do
  use GenServer

  def start_link(val) do
      GenServer.start_link(__MODULE__, val)
  end

  def init(val) do
      hashtags = :ets.new(:hashtags, [:set, :public, :named_table, read_concurrency: true])
      mentions = :ets.new(:mentions, [:set, :public, :named_table, read_concurrency: true])
      allTweets = :ets.new(:allTweets, [:set, :public, :named_table, read_concurrency: true])
      allReTweets = :ets.new(:allReTweets, [:set, :public, :named_table, read_concurrency: true])
      counter = :ets.new(:counter, [:set, :public, :named_table, read_concurrency: true])
      user_list = :ets.new(:user_list, [:set, :public, :named_table])
      followers = :ets.new(:followers,[:set, :public, :named_table, read_concurrency: true])
      :ets.insert(:counter,{"tweets",0})
      :ets.insert(:counter,{"total_users",0})
      :global.register_name(:Twitter_Engine,self())

      {:ok,val}

  end

def handle_cast({:register,user,userNum},state) do
  :ets.insert(:user_list,{userNum,user})
  :ets.insert(:followers,{user,[]})
  :ets.insert(:allTweets,{user,[]})
  :ets.insert(:allReTweets,{user,[]})
  :ets.insert(:mentions,{user,[]})
  {:noreply,state}
end

def printusercount() do
Enum.each(0..49, fn userNum -> [{userNum,user}]=:ets.lookup(:user_list,userNum)
                              IO.inspect(user)
                            end)
50
end

def getUserCount() do
  info = :ets.info(:user_list)
  info[:size]
end

def verifyMentions() do
  info = :ets.info(:mentions)
  info[:size]
end

def verifyTweets(numUsers,numTweets,user_pids,regularUsers) do

  :ets.new(:verifyTweets, [:set, :public, :named_table, read_concurrency: true])
  info = :ets.info(:allTweets)
  if(info[:size] == numUsers) do
    :ets.insert(:verifyTweets,{"result","Tweet test case passed"})
  else
    :ets.insert(:verifyTweets,{"result","Tweet test case failed"})
  end

  Enum.each(0..regularUsers-1, fn user ->   [{_,all_Tweets}]=:ets.lookup(:allTweets,Enum.at(user_pids,user))
                                        len = length(all_Tweets)
                                        #IO.puts("#{len}")
                                        if(len == numTweets) do
                                          :ets.insert(:verifyTweets,{"result","Tweet test case passed"})
                                        else
                                          :ets.insert(:verifyTweets,{"result","Tweet test case failed"})
                                        end
                              end)

  Enum.each(regularUsers..numUsers-1, fn user ->   [{_,all_Tweets}]=:ets.lookup(:allTweets,Enum.at(user_pids,user))
                                        len = length(all_Tweets)
                                        #IO.puts("#{len}")
                                        if(len == numTweets+1) do
                                          :ets.insert(:verifyTweets,{"result","Tweet test case passed"})
                                        else
                                          :ets.insert(:verifyTweets,{"result","Tweet test case failed"})
                                        end
                              end)

   [{_,result}]=:ets.lookup(:verifyTweets,"result")
  result
end

def verifyFollowers(numUsers,sCount,user_pids,regularUsers) do

  :ets.new(:verifyFollowers, [:set, :public, :named_table, read_concurrency: true])
  info = :ets.info(:followers)
  if(info[:size] == numUsers) do
    :ets.insert(:verifyFollowers,{"result","Followers test case passed"})
  else
    :ets.insert(:verifyFollowers,{"result","Followers test case failed"})
  end

  Enum.each(0..regularUsers-1, fn user ->   [{_,all_followers}]=:ets.lookup(:followers,Enum.at(user_pids,user))
                                        len = length(all_followers)
                                      #  IO.puts("#{len}")
                                        if(len == sCount) do
                                          :ets.insert(:verifyFollowers,{"result","Followers test case passed"})
                                        else
                                          :ets.insert(:verifyFollowers,{"result","Followers test case failed"})
                                        end
                              end)

Enum.each(regularUsers..numUsers-1, fn user ->   [{_,all_followers}]=:ets.lookup(:followers,Enum.at(user_pids,user))
                                      len = length(all_followers)
                                    #  IO.puts("#{len}")
                                      if(len == sCount+1) do
                                        :ets.insert(:verifyFollowers,{"result","Followers test case passed"})
                                      else
                                        :ets.insert(:verifyFollowers,{"result","Followers test case failed"})
                                      end
                            end)

   [{_,result}]=:ets.lookup(:verifyFollowers,"result")
  result
end

def verifyRetweets() do
  info = :ets.info(:followers)
  info[:size]
end

def verifyHashTags() do

  info = :ets.info(:hashtags)
  len = info[:size]
  [{_,allTweets}]=:ets.lookup(:hashtags,"COP5615isgreat")
  numTweet = length(allTweets)
  size = numTweet * len
  size

end

def printHashTags() do
  [{_,allTweets}]=:ets.lookup(:hashtags,"COP5615isgreat")
  IO.inspect(allTweets)
end

def printfollowers(user_pids,numUsers) do
Enum.each(0..numUsers-1, fn user ->   [{user,followerId}]=:ets.lookup(:followers,Enum.at(user_pids,user))
  IO.inspect(followerId)
                            end)
end

def printTweets(user_pids,numUsers) do
Enum.each(0..numUsers-1, fn user ->   [{_,all_Tweets}]=:ets.lookup(:allTweets,Enum.at(user_pids,user))
  IO.inspect(all_Tweets)
                            end)
end

def handle_cast({:add_follower,user,followerIds}, state) do
  :ets.insert(:followers,{user,followerIds})
  {:noreply,state}
end

def registerUser(user,userNum,engine) do
#IO.puts("In engine")
  GenServer.cast(engine,{:register,user,userNum})
#  User.message_receiver("userRegistered")
end

def subscribe(user,followerList,engine) do
  GenServer.cast(engine,{:add_follower,user,followerList})
#  User.message_receiver("followerAdded")
end

def tweet(user,value,user_pids,engine) do
  GenServer.cast(engine,{:update_tweet,value,user})
  publishTweet(user,value)
  notifyTaggedPeople(user,value,user_pids)
  findHashTags(value)
end

def findHashTags(tweet_value) do
    wordList=String.split(tweet_value," ",trim: true)
    len = length(wordList)
    Enum.each(1..len, fn i -> val = Enum.at(wordList,i)
                              if(String.at(val,0) == "#") do
                                slen = String.length(val)
                                hashTag = String.slice(val,1..len-1)

                                if :ets.member(:hashtags, hashTag) do

                                  [{_,allTweets}]=:ets.lookup(:hashtags,hashTag)

                                  :ets.insert(:hashtags,{hashTag,allTweets ++ [tweet_value]})
                                else
                                    :ets.insert(:hashtags,{hashTag,[tweet_value]})
                                end

                              end
                      end)
end

  def retweet(user,value,engine) do
  GenServer.cast(engine,{:update_retweet,value,user})
end

def handle_cast({:update_retweet,value,user},state) do
  [{_,allReTweets}]=:ets.lookup(:allReTweets,user)
  :ets.insert(:allReTweets,{user,allReTweets ++ [value]})
  {:noreply,state}
end

def handle_cast({:update_tweet,value,user},state) do
  [{_,current_tweet_count}]=:ets.lookup(:counter,"tweets")
  [{_,all_tweets}]=:ets.lookup(:allTweets,user)
  :ets.insert(:counter,{"tweets",current_tweet_count+1})
  :ets.insert(:allTweets,{user,all_tweets ++ [value]})

  {:noreply,state}
end

def notifyTaggedPeople(user,tweet_value,user_pids) do
    wordList=String.split(tweet_value," ",trim: true)
    len = length(wordList)
    Enum.each(1..len, fn i -> val = Enum.at(wordList,i)
                              if(String.at(val,0) == "@") do
                                slen = String.length(val)
                                taggedUser = String.slice(val,1..len-1)
                                taggedPId = Enum.at(user_pids,String.to_integer(taggedUser))
                                [{_,allMentions}]=:ets.lookup(:mentions,taggedPId)
                                :ets.insert(:mentions,{taggedPId,allMentions ++ [tweet_value]})
                                User.tagged(taggedUser,tweet_value,user_pids)
                              end
                      end)
  end

  def get_info_hashtags() do
    info = :ets.info(:hashtags)
    IO.inspect(info)

    info = :ets.info(:user_list)
    IO.inspect(info)
  end

  def publishTweet(user,tweet_value) do
        [{_,followerList}]=:ets.lookup(:followers,user)
        len=length(followerList)
      Enum.each(0..len-1, fn fid -> if(rem(fid,2)==0) do
                                      User.publishTweet(Enum.at(followerList,fid),tweet_value,1)
                                    else
                                      User.publishTweet(Enum.at(followerList,fid),tweet_value,0)
                                    end
                                     end)
  end

end
