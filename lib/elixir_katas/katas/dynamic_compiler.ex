defmodule ElixirKatas.Katas.DynamicCompiler do
  @moduledoc """
  Compiles user code into ephemeral modules for isolation.
  """

  def compile(user_id, kata_name, source_code) do
    # 1. Generate unique module name
    # e.g. ElixirKatas.UserID.KataName
    module_name = Module.concat(["ElixirKatas", "User#{user_id}", Macro.camelize(kata_name)])
    
    # 2. Rewrite the source code to use this module name
    # We use a more robust regex that handles multiline and varying whitespaces
    new_source = 
      Regex.replace(
        ~r/defmodule\s+[\w\.]+\s+do/s, 
        source_code, 
        "defmodule #{module_name} do", 
        global: false
      )

    # 3. Compile
    try do
      # Purge old version if exists to avoid "redefining module" warnings/errors
      if Code.ensure_loaded?(module_name) do
        :code.purge(module_name)
        :code.delete(module_name)
      end
      
      Code.compile_string(new_source)
      {:ok, module_name}
    rescue
      e -> 
        {:error, Exception.message(e)}
    catch
      kind, error -> 
        {:error, "Compile-time error (#{kind}): #{inspect(error)}"}
    end
  end
end
