defmodule Project4part2 do
    @moduledoc """
    Project4part2 keeps the contexts that define your domain
    and business logic.

    Contexts are also responsible for managing your data, regardless
    if it comes from the database, an external API or others.
    """
    use Application
    require Logger
    def start(_type, _args) do

        import Supervisor.Spec

        # Define workers and child supervisors to be supervised
        children = [
          # Start the endpoint when the application starts
          supervisor(Project4part2Web.Endpoint, []),
          # Start your own worker by calling: Twitter.Worker.start_link(arg1, arg2, arg3)
          # worker(Twitter.Worker, [arg1, arg2, arg3]),
        ]
        init()
        opts = [strategy: :one_for_one, name: Project4part2.Supervisor]
        Supervisor.start_link(children, opts)
    end
    def init() do
        hashtags = :ets.new(:hashtags, [:set, :public, :named_table, read_concurrency: true])
        offfeed = :ets.new(:offfeed, [:set, :public, :named_table, read_concurrency: true])
        offfollowers = :ets.new(:offfollowers, [:set, :public, :named_table, read_concurrency: true])
        offmentions = :ets.new(:offmentions, [:set, :public, :named_table, read_concurrency: true])
        onfollowers = :ets.new(:onfollowers, [:set, :public, :named_table, read_concurrency: true])
        onmentions = :ets.new(:onmentions, [:set, :public, :named_table, read_concurrency: true])
        curr_mentioned = :ets.new(:curr_mentioned, [:set, :public, :named_table, read_concurrency: true])
        mentions = :ets.new(:mentions, [:set, :public, :named_table, read_concurrency: true])
        allTweets = :ets.new(:allTweets, [:set, :public, :named_table, read_concurrency: true])
        allReTweets = :ets.new(:allReTweets, [:set, :public, :named_table, read_concurrency: true])
        counter = :ets.new(:counter, [:set, :public, :named_table, read_concurrency: true])
        user_list = :ets.new(:user_list, [:set, :public, :named_table])
        :ets.new(:users, [:set, :public, :named_table, read_concurrency: true])
        followers = :ets.new(:followers,[:set, :public, :named_table, read_concurrency: true])
        :ets.insert(:counter,{"tweets",0})
        :ets.insert(:counter,{"total_users",0})
        :ets.insert(:counter,{"online_users",0})
      #  :global.register_name(:Twitter_Engine,self())
    end

end
