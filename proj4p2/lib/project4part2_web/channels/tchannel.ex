defmodule Project4part2Web.Tchannel do
  use Phoenix.Channel

  def join("timeline:feed", payload, socket) do
    username = payload["username"]
    :ets.insert(:user_list,{username,"online"})
  :ets.insert(:offfeed,{username,[]})
  :ets.insert(:followers,{username,[]})
   :ets.insert(:allTweets,{username,[]})
   :ets.insert(:allReTweets,{username,[]})
   :ets.insert(:mentions,{username,[]})
   [{_,status}]=:ets.lookup(:user_list,username)
   if(status == "online") do
   IO.puts("successfully registered with online status")
   end

    {:ok, socket}
  end

  def handle_in("myMentions", params, socket) do
      [{_,mentionss}] = :ets.lookup(:mentions,params["username"])
      {:reply, {:ok, %{ "mentionss" => mentionss}}, socket}
  end

  def handle_in("add_follower", params, socket) do

  username = params["username"]
    if ((:ets.member(:user_list, username)) == false) do
      IO.puts("in not a member")
      {:reply, {:ok, %{ "message" => "Please register to enjoy using twitter"}}, socket}

    else
        [{_,status}] = :ets.lookup(:user_list,username)
        if(status == "offline") do
          {:reply, {:ok, %{ "message" => "Please login to continue using twitter functionality"}}, socket}
        else
              if :ets.member(:user_list, params["follower"]) do

                username = params["username"]
                follower = params["follower"]

              [{_,all_followers}]=:ets.lookup(:followers,follower)
              :ets.insert(:followers,{follower,all_followers ++ [username]})
          #    IO.puts "printing followerlist of: #{follower}"
              [{_,followerList}]=:ets.lookup(:followers,follower)

                  {:reply, {:ok, %{ "message" => "Successfully subscribed"}}, socket}
              else
                {:reply, {:ok, %{ "message" => "The user you want to follow does not exist"}}, socket}
              end
          end
      end
  end

  def handle_in("tweet", params, socket) do
      username = params["username"]
      value =  params["value"]
    username = params["username"]
      if ((:ets.member(:user_list, username)) == false) do
        IO.puts("in not a member")
        {:reply, {:ok, %{ "message" => "Please register to enjoy using twitter"}}, socket}

      else
          [{_,status}] = :ets.lookup(:user_list,username)
          if(status == "offline") do
            {:reply, {:ok, %{ "message" => "Please login to continue using twitter functionality"}}, socket}
          else
              wordList=String.split(value," ",trim: true)
              len = length(wordList)


              :ets.insert(:curr_mentioned,{value,[]})

              Enum.each(1..len, fn i -> val = Enum.at(wordList,i)
                                        if(String.at(val,0) == "@") do
                                          slen = String.length(val)
                                          taggedUser = String.slice(val,1..slen-1)
                                          [{_,allMentions}]=:ets.lookup(:curr_mentioned,value)
                                          :ets.insert(:curr_mentioned,{value,allMentions ++ [taggedUser]})
                                          [{_,myMentions}]=:ets.lookup(:mentions,taggedUser)
                                          :ets.insert(:mentions,{taggedUser,myMentions ++ [value]})
                                        #  [{_,allMentions}]=:ets.lookup(:curr_mentioned,value)

                                        end
                                end)


            #  IO.puts("user is #{username} and value is #{value}")
              [{_,current_tweet_count}]=:ets.lookup(:counter,"tweets")
              [{_,all_tweets}]=:ets.lookup(:allTweets,username)
              :ets.insert(:counter,{"tweets",current_tweet_count+1})
            #  IO.puts("trying to update values")
              :ets.insert(:allTweets,{username,all_tweets ++ [value]})
            #  IO.puts("updated values")
            #  IO.puts("printing follower list now")

              wordList=String.split(value," ",trim: true)
              len = length(wordList)
              Enum.each(1..len, fn i -> val = Enum.at(wordList,i)
                                       if(String.at(val,0) == "#") do
                                         slen = String.length(val)
                                         hashTag = String.slice(val,1..slen-1)

                                         if :ets.member(:hashtags, hashTag) do

                                           [{_,allTweets}]=:ets.lookup(:hashtags,hashTag)

                                           :ets.insert(:hashtags,{hashTag,allTweets ++ [value]})
                                         else
                                             :ets.insert(:hashtags,{hashTag,[value]})
                                         end

                                       end
                               end)

              [{_,followerList}]=:ets.lookup(:followers,username)
              len=length(followerList)
              [{_,mentionedList}] =:ets.lookup(:curr_mentioned,value)

               :ets.insert(:offfollowers,{username,[]})
               :ets.insert(:offmentions,{username,[]})
               :ets.insert(:onfollowers,{username,[]})
               :ets.insert(:onmentions,{username,[]})

              for follower <- followerList do
                  [{_,status}] = :ets.lookup(:user_list,follower)
                  if(status == "online") do
                      [{_,onfollowers1}] = :ets.lookup(:onfollowers,username)
                      :ets.insert(:onfollowers, {username, onfollowers1 ++ [follower]})
                  else
                      [{_,offfollowers1}] = :ets.lookup(:offfollowers,username)
                      :ets.insert(:offfollowers,{username, offfollowers1 ++ [follower]})
                  end
              end

              for mentioned <- mentionedList do

                  [{_,status}] = :ets.lookup(:user_list,mentioned)

                  if(status == "online") do
                    IO.puts("in online")
                      [{_,onmentions1}] = :ets.lookup(:onmentions,username)
                      :ets.insert(:onmentions,{username, onmentions1 ++ [mentioned]})
                  else
                    IO.puts("in offlien")
                      [{_,offmentions1}] = :ets.lookup(:offmentions,username)
                      :ets.insert(:offmentions, {username, offmentions1 ++ [mentioned]})
                  end
              end

              [{_,offfollowers1}] = :ets.lookup(:offfollowers,username)
              [{_,onfollowers1}] = :ets.lookup(:onfollowers,username)
              [{_,offmentions1}] = :ets.lookup(:offmentions,username)
              [{_,onmentions1}] = :ets.lookup(:onmentions,username)

              senderList = onfollowers1 ++ onmentions1

              for offf <- offfollowers1 do
                  [{_,offfeed1}] = :ets.lookup(:offfeed,offf)
                  :ets.insert(:offfeed, {offf, offfeed1 ++ [value]})
              end

              for offf <- offmentions1 do
                  [{_,offfeed1}] = :ets.lookup(:offfeed,offf)
                  :ets.insert(:offfeed, {offf, offfeed1 ++ [value]})
              end

              if(length(senderList) > 0) do

                params = Map.put(params, "senderList" , senderList)
                broadcast_from! socket, "tweet", params
              end
          end
      end
      {:noreply, socket}
    end


  def handle_in("hashtagTweets", params, socket) do

  username = params["username"]
    if ((:ets.member(:user_list, username)) == false) do
      IO.puts("in not a member")
      {:reply, {:ok, %{ "message" => "Please register to enjoy using twitter"}}, socket}

    else
        [{_,status}] = :ets.lookup(:user_list,username)
        if(status == "offline") do
          {:reply, {:ok, %{ "message" => "Please login to continue using twitter functionality"}}, socket}
        else
            hashtag = params["hashtag"]

            if :ets.member(:hashtags, hashtag) do
                [{_,allTweets}] = :ets.lookup(:hashtags,hashtag)
              #  IO.puts("printing all hastags")
              #  IO.inspect(allTweets)
                {:reply, {:ok, %{ "tweets" => allTweets, "username" => params["username"]}}, socket}
            else
                {:reply, {:ok, %{ "tweets" => [], "username" => params["username"]}}, socket}
            end
      end
    end
  end

  def handle_in("deactivateAccount", params, socket) do
    username = params["username"]

    :ets.delete(:user_list, username)
    :ets.delete(:followers, username)
    :ets.delete(:allTweets, username)
    :ets.delete(:allReTweets, username)
    :ets.delete(:user_list, username)
    :ets.delete(:mentions,username)

  #  broadcast_from! socket, "deactivateAccount", params
    {:noreply, socket}

  end

  def handle_in("login", params, socket) do
  username = params["username"]
    if ((:ets.member(:user_list, username)) == false) do
      IO.puts("in not a member")
      {:reply, {:ok, %{ "message" => "Please register to enjoy using twitter"}}, socket}

    else
            username=params["username"]
            :ets.insert(:user_list,{username,"online"})
            [{_,offfeed1}] = :ets.lookup(:offfeed,username)
            {:reply, {:ok, %{"feed" => offfeed1, "username"=> username}}, socket}
    end

  end

  def handle_in("logout", params, socket) do
     username=params["username"]
     IO.puts "UPDATING USER #{username} AS OFFLINE"
     :ets.insert(:user_list,{username,"offline"})
     :ets.insert(:users,{username,{2,:off}})
    {:noreply, socket}
  end


end
