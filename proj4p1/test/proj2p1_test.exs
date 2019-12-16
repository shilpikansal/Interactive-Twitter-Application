defmodule Proj2p1Test do
  use ExUnit.Case
  doctest Proj2p1

  setup do
    Mix.Tasks.Twitter.main()
    :ok
  end

  test "registration/2 check registration" do
    userNum = 1000
    tcount = 2
    assert Mix.Tasks.Twitter.registration(userNum) == userNum
    assert Mix.Tasks.Twitter.subscriptions(userNum,tcount)=="Followers test case passed"
    assert Mix.Tasks.Twitter.tweets(userNum,tcount)=="Tweet test case passed"
    assert Mix.Tasks.Twitter.reTweetsTestCase >= 1
    assert Mix.Tasks.Twitter.hashTags == tcount * userNum
    assert Mix.Tasks.Twitter.mentionsTestCase >= 1
  end

end
