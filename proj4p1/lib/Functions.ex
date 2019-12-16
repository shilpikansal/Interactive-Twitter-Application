defmodule Mix.Tasks.Functions do

  def randomizer(length) do
    #IO.puts("In randomizer")
    list = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789"
    #numbers = "0123456789"
    #list = alphabets <> numbers

    val = generate_random_string(length,"",list)
    IO.puts("In randomizer, value returned is: #{val}")
    val
  end

  def generate_random_string(length,val,list) do
    if(length > 0) do
      randIndex = :rand.uniform(length)
      val = val <> String.at(val,randIndex)
      generate_random_string(length-1,val,list)
    else
      val
    end
  end

end
