defmodule Anvil do
  @moduledoc """
  Defines functions for generating data

  ## Examples

      defmodule MyApp.Anvil do
        use Anvil

        def factory(:config) do
          # Factories can be plain maps
          %{url: "http://example.com"}
        end

        def factory(:article) do
          %Article{
            title: "My Awesome Article"
          }
        end

        def factory(:comment, opts) do
          %Comment{
            body: "This is great!",
            article_id: assoc(opts, :article).id
          }
        end

        def create_record(map) do
          # This example uses Ecto to save records
          MyApp.Repo.insert!(map)
        end
      end
  """

  defmodule UndefinedFactory do
    @moduledoc """
    Error raised when trying to build or create a factory that is undefined.
    """

    defexception [:message]

    def exception(factory_name) do
      message = "No factory defined for #{inspect factory_name}"
      %UndefinedFactory{message: message}
    end
  end

  defmacro __using__(_opts) do
    quote do
      @before_compile unquote(__MODULE__)

      def assoc(opts, factory_name) do
        Anvil.assoc(__MODULE__, opts, factory_name)
      end

      def build(factory_name, opts \\ %{}) do
        Anvil.build(__MODULE__, factory_name, opts)
      end

      def create(factory_name, opts \\ %{}) do
        Anvil.create(__MODULE__, factory_name, opts)
      end

      def create_pair(factory_name, opts \\ %{}) do
        Anvil.create_pair(__MODULE__, factory_name, opts)
      end

      def create_list(number_of_factorys, factory_name, opts \\ %{}) do
        Anvil.create_list(__MODULE__, number_of_factorys, factory_name, opts)
      end
    end
  end

  @doc """
  Gets a factory from the passed in opts, or creates if none is present

  ## Examples

      opts = %{user: %{name: "Someone"}}
      # Returns opts.user
      assoc(opts, :user) 

      opts = %{}
      # Creates and returns new instance based on :user factory
      assoc(opts, :user)
  """
  def assoc(module, opts, factory_name) do
    if Map.has_key?(opts, factory_name) do
      Map.get(opts, factory_name)
    else
      Anvil.create(module, factory_name)
    end
  end

  @doc """
  Builds a factory with the passed in factory_name

  ## Example

      def factory(:user) do
        %{name: "John Doe", admin: false}
      end

      # Returns %{name: "John Doe", admin: true}
      build(:user, admin: true)
  """
  def build(module, factory_name, opts \\ %{}) do
    opts = Enum.into(opts, %{})
    module.factory(factory_name, opts) |> Map.merge(opts)
  end

  @doc """
  Builds a factory with the passed in factory_name and saves with create_record

  ## Example

      def create_record(record) do
        # This example uses Ecto
        MyApp.Repo.insert!(record)
      end

      def factory(:user) do
        %{name: "John Doe", admin: false}
      end

      # Saves and returns %{name: "John Doe", admin: true}
      create(:user, admin: true)
  """
  def create(module, factory_name, opts \\ %{}) do
    Anvil.build(module, factory_name, opts) |> module.create_record
  end

  @doc """
  Creates and returns 2 records with the passed in factory_name and opts

  ## Example

      # Returns a list of 2 users
      create_pair(:user)
  """
  def create_pair(module, factory_name, opts \\ %{}) do
    Anvil.create_list(module, 2, factory_name, opts)
  end

  @doc """
  Creates and returns X records with the passed in factory_name and opts

  ## Example

      # Returns a list of 3 users
      create_pair(3, :user)
  """
  def create_list(module, number_of_factories, factory_name, opts \\ %{}) do
    Enum.map(1..number_of_factories, fn(_) ->
      Anvil.create(module, factory_name, opts)
    end)
  end

  defmacro __before_compile__(_env) do
    quote do
      @doc """
      Calls factory/1 with the passed in factory name

      This allows you to define factorys without the second `opts` param.
      """
      def factory(factory_name, _opts) do
        __MODULE__.factory(factory_name)
      end

      @doc """
      Raises a helpful error if no factory is defined.
      """
      def factory(factory_name) do
        raise UndefinedFactory, factory_name
      end
    end
  end
end
