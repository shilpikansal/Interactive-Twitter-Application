defmodule Proj4p1bonusTest do
  use ExUnit.Case
  doctest Proj4p1bonus

  setup do

    Mix.Tasks.Twitter.main()
    :ok
  end

  test "registration/2 check registration" do
    userNum = 1000
    tcount = 2
    zipf_factor = 0.4
    regularUsers = round(userNum * zipf_factor)
    specialUsers = userNum - regularUsers
    expected_hashtags = (specialUsers * (tcount+1)) + (regularUsers * tcount)
    assert Mix.Tasks.Twitter.registration(userNum) == userNum
    assert Mix.Tasks.Twitter.subscriptions(userNum,tcount,regularUsers)=="Followers test case passed"
    assert Mix.Tasks.Twitter.tweets(userNum,tcount,regularUsers)=="Tweet test case passed"
    assert Mix.Tasks.Twitter.reTweetsTestCase >= 1
    assert Mix.Tasks.Twitter.hashTags == expected_hashtags
    assert Mix.Tasks.Twitter.mentionsTestCase >= 1
  end

end
