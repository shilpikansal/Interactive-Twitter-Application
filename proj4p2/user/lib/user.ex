defmodule User do

require Logger

def main(args) do
  {_, args, _} = OptionParser.parse(args)
  server_ip = Enum.at(args, 0)
  port = 4001
  create_server_connection(server_ip)
end

def create_server_connection(server_ip) do
  #  IO.puts("here")
    {:ok, pid} = PhoenixChannelClient.start_link()
    username = IO.gets "Please enter your username to register: "
    username = String.trim(username)

    {:ok, socket} = PhoenixChannelClient.connect(pid,
        host: server_ip,
        port: 4001,
        path: "/socket/websocket",
        params: %{token: "whatever", username: username},
        secure: false)

    tchannel = PhoenixChannelClient.channel(socket, "timeline:feed", %{username: username})

    case PhoenixChannelClient.join(tchannel) do
        {:ok, %{}} -> :ok
        {:error, %{reason: reason}} -> IO.puts(reason)
        :timeout -> IO.puts("timeout")
      end

    start_client(username,tchannel,pid,server_ip)
end

def start_client(username,tchannel,pid,server_ip) do
#  IO.puts("In start")
  GenServer.start_link(__MODULE__,%{})
#  IO.puts("You have registered successfully")

  spawn_pid = spawn fn -> get_action(tchannel, username) end
  listen(username, tchannel, spawn_pid, pid, server_ip)
end

def init(map) do
    {:ok, map}
end

  def get_action(tchannel, username) do
      option = IO.gets "Options:\n1. Subscribe\n2. Hashtag query\n3. Tweet\n4. Delete account\n5. Logout \n6. Login \n7. My mentions \nEnter your choice: "
      case String.trim(option) do

          "1" -> follower = IO.gets "Enter username you want to follow: "
                 follower = String.trim(follower)
                 subscribe(tchannel, follower, username)

          "2" -> hashtag = IO.gets "Enter the hashtag that you want to search: "
                 hashtag = String.trim(hashtag)
                 findHashtagTweets(tchannel, hashtag, username)

          "3" -> tweet = IO.gets "Enter tweet: "
                tweet = String.trim(tweet)
                sendTweet(tchannel, tweet, username)

          "4" -> deactivateAccount(tchannel, username)

          "5" -> logout(tchannel,username)

          "6" -> login(tchannel,username)

          "7"  -> myMentions(tchannel,username)

          _ -> IO.puts "Invalid option. Please try again"
      end
      get_action(tchannel, username)
  end

  def sendTweet(tchannel,value,username) do
    data = %{"username"=> username, "value"=> value}
    PhoenixChannelClient.push(tchannel, "tweet", data)
  end

  def myMentions(tchannel,username) do
      data = %{"username"=> username}
      {:ok, data1}  =  PhoenixChannelClient.push_and_receive(tchannel, "myMentions", data,150)
      mentionss = data1["mentionss"]

      IO.puts("You have been entioned in the following tweets")

      for mention <- mentionss do
          IO.puts "Tweet: #{mention}"
      end
  end

  def subscribe(tchannel, follower, username) do
    data = %{"username"=> username, "follower"=> follower}
    {:ok, data1}  =  PhoenixChannelClient.push_and_receive(tchannel, "add_follower", data,150)
    message = data1["message"]
    IO.puts("#{message}")
  end

  def login(tchannel,username) do
  #  IO.puts("in login user")
     data= %{"username" => username}
     {:ok, data1}  = PhoenixChannelClient.push_and_receive(tchannel, "login", data, 150)
       allfeed = data1["feed"]

       IO.puts("You received following tweets while you were offline")

       for feed <- allfeed do
           IO.puts "Tweet: #{feed}"
       end
  end

  def logout(tchannel,username) do
    #:ets.insert(:status,{username,"offline"})
     data= %{"username" => username}
     PhoenixChannelClient.push(tchannel,"logout",data)
  end

  def findHashtagTweets(tchannel,hashtag,username) do

      data = %{"username"=> username, "hashtag"=> hashtag}
      {:ok, data1}  = PhoenixChannelClient.push_and_receive(tchannel, "hashtagTweets", data, 150)

      alltweets = data1["tweets"]

      for tweet <- alltweets do
          IO.puts "Tweet: #{tweet}"
      end
  end

  def deactivateAccount(tchannel,username) do
    data = %{"username"=> username}
    PhoenixChannelClient.push(tchannel, "deactivateAccount", data)

  end

  def listen(username, tchannel, spawn_pid, pid, server_ip) do
  receive do
    {"tweet", data} ->
      #IO.puts("In here...listened to the tweet")
      sender = data["username"]
      tweet = data["value"]
      Logger.info "user :#{sender} has tweeted: #{tweet}"
      retweet = IO.gets "Do you want to retweet? (y/n): "
      retweet = String.trim(retweet)
      if retweet == "y" do
          sendTweet(tchannel,tweet,username)
      end

    {"deactivateAccount",data} -> IO.puts("hello deactivatng myself")
    Process.exit(spawn_pid, :kill)

    :close -> Process.exit(spawn_pid, :kill)
    {:ok, socket} = PhoenixChannelClient.connect(pid,
          host: server_ip,
          port: 4001,
          path: "/socket/websocket",
          params: %{token: "something", username: username},
          secure: false)

      tchannel = PhoenixChannelClient.channel(socket, "timeline:feed", %{username: username})

      PhoenixChannelClient.join(tchannel)

      spawn_pid = spawn fn -> get_action(tchannel, username) end
    {:error, error} -> ()
  after
    100000 ->
  end
  listen(username, tchannel, spawn_pid, pid, server_ip)
end

end
