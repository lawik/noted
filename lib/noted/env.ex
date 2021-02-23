defmodule Noted.Env do
  require Logger

  def require(environment_variable) do
    case System.get_env(environment_variable) do
      nil ->
        Logger.error("Missing required environment variable: #{environment_variable}")

        raise "Missing required environment variable: #{environment_variable}"

      value ->
        value
    end
  end

  def expect(environment_variable, default \\ nil) do
    case System.get_env(environment_variable) do
      nil ->
        Logger.warn("Expected environment variable not set: #{environment_variable}")
        default

      value ->
        value
    end
  end
end
