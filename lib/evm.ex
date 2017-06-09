defmodule Exthereum.EVM do
  alias Exthereum.EVM.Stack
  alias Exthereum.EVM.Log
  alias Exthereum.EVM.Storage
  alias Exthereum.EVM.Gas
  use Exthereum.EVM.Opcodes
  use Exthereum.EVM.Utils

  def run(state, code) do
    step(state, code, [], 0)
  end

  def step(state, code, stack, program_counter) do
    opcode = :binary.at(code, program_counter)

    stack = Stack.step(stack, code, program_counter, opcode)
    storage = state[:accounts][state[:from]]["storage"]
    state = update_in(state[:gas], &(&1 - Gas.price(stack, storage, opcode)))
    state = update_in(
      state,
      [:accounts, state[:from], "storage"],
      &Storage.step(&1, stack, opcode)
    )
    Log.step(stack, code, program_counter, opcode)

    if program_counter + 1 < byte_size(code) do
      step(
        state,
        code,
        stack,
        next_instruction(program_counter, opcode)
      )
    else
      state
    end
  end

  def next_instruction(program_counter, opcode) do
    if is_push_opcode(opcode) do
      program_counter + size_of_push(opcode) + 1
    else
      program_counter + 1
    end
  end
end
