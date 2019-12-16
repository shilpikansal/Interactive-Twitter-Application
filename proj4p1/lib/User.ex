defmodule User do
    use GenServer

  def start_link(val) do
        GenServer.start_link(__MODULE__, val)
  end

  def init(val) do
    userNum = Enum.at(val,0)

    Engine.registerUser(self(),userNum,:global.whereis_name(:Twitter_Engine))

    {:ok, %{"my_tweets" => [], "number" => Enum.at(val,0), "my_followers" => [], "received_tweets" => [], "retweets" => [],
    "my_tags" => []   }}
  end


  def  handle_cast({:add_follower, sId}, state) do
     {:ok, my_followers} = Map.fetch(state,"my_followers")
     {:noreply,Map.put(state,"my_followers",my_followers ++ [sId])}
   end

  def handle_cast({:tweet, value }, state) do
    {:ok, all_tweets} = Map.fetch(state, "my_tweets")
    {:noreply, Map.put(state, "my_tweets",all_tweets ++ [value] )}
  end

  def handle_cast({:retweet,value}, state) do
    {:ok, retweets} = Map.fetch(state, "retweets")
    #IO.inspect(retweets)
    {:noreply, Map.put(state, "retweets", retweets ++ [value] )}
  end

  def handle_cast({:my_tags,value}, state) do
    {:ok, tags} = Map.fetch(state, "my_tags")
  #  IO.puts("I have been tagged")
    {:noreply, Map.put(state, "my_tags", tags ++ [value] )}
  end

  def subscribe(user,sId) do
  GenServer.cast(user,{:add_follower,sId})
  {:ok, followerList} = GenServer.call(user,{:get_followers})
  Engine.subscribe(user, followerList,:global.whereis_name(:Twitter_Engine))
  end

  def sendTweet(user,value,user_pids) do
    GenServer.cast(user, {:tweet,value})
    {:ok, all_tweets} = GenServer.call(user,{:get_all_tweets})
    Engine.tweet(user,value,user_pids,:global.whereis_name(:Twitter_Engine))
  end

  def tagged(userNum, tweet_value,user_pids) do
    userNum = String.to_integer(userNum)
    GenServer.cast(Enum.at(user_pids,userNum),{:my_tags,tweet_value})
  end

  def publishTweet(user,tweet_value,retweet_or_not) do
      GenServer.cast(user,{:receive_tweet,tweet_value})

      # if retweet_or_not is 1 then retweet else don't retweet
      if(retweet_or_not == 1) do
        #IO.puts("I am going to retqeet: #{tweet_value}")
        reTweet(user,tweet_value)
      end
  end

  def reTweet(user,value) do
    GenServer.cast(user, {:retweet,value})
    Engine.retweet(user,value,:global.whereis_name(:Twitter_Engine))
  end

  def handle_cast({:receive_tweet,value}, state) do
    {:ok, receivedTweets} = Map.fetch(state,"received_tweets")

    {:noreply,Map.put(state,"received_tweets",receivedTweets ++ [value])}
  end



  def handle_call({:get_all_tweets}, _from, state) do
      {:reply, Map.fetch(state,"my_tweets"), state}
  end

  def handle_call({:get_followers}, _from, state) do
      {:reply, Map.fetch(state,"my_followers"), state}
  end

  def handle_cast({:subscribe, who }, state) do
    {:ok, subscribers} = Map.fetch(state, "subscribers")
    subscribers = subscribers ++ [who]
    {:noreply, Map.put(state, "subscribers",subscribers )}
  end



end
