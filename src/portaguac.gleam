import argv
import gleam/io
import gleam/option.{type Option}
import gleam/string
import simplifile

pub type Headmatter {
  Headmatter(key: String, value: String)
}

pub type Format {
  Format(name: String, template: String)
}

pub type Ingredient {
  Ingredient(name: String, amount: String, adjectives: List(String))
}

pub type Instruction {
  Instruction(action: String, ingredients: List(Ingredient))
}

pub type Step {
  Step(name: Option(String), instructions: List(Instruction), steps: List(Step))
}

pub type LexedRecipe {
  LexedRecipe(
    headmatter: List(Headmatter),
    formats: List(Format),
    steps: List(Step),
  )
}

pub type LexError {
  InsufficientArguments
}

pub fn main() {
  case argv.load().arguments {
    [file, ..] ->
      case simplifile.read(from: file) {
        Ok(recipe) -> lex(recipe) |> string.inspect |> io.println
        Error(error) ->
          io.println_error(
            "Could not read file: " <> simplifile.describe_error(error),
          )
      }
    _ -> io.println_error("I don't know where to go!")
  }
}

pub fn lex(source: String) -> LexedRecipe {
  let lines: List(String) = string.split(source, on: "\n")
  let empty_recipe: LexedRecipe =
    LexedRecipe(headmatter: [], formats: [], steps: [])
  lex_loop(lines, empty_recipe)
}

fn lex_loop(source: List(String), recipe: LexedRecipe) -> LexedRecipe {
  case source {
    [] -> recipe
    ["!" <> content, ..rest] ->
      case headmatter(string.trim(content)) {
        Ok(headmatter) ->
          lex_loop(
            rest,
            LexedRecipe(..recipe, headmatter: [headmatter, ..recipe.headmatter]),
          )
        Error(InsufficientArguments) -> {
          io.println_error("Incorrect number of headmatter arguments.
            Got: `!" <> content <> "`
            Expected: `![key] [value]`")
          lex_loop(rest, recipe)
        }
      }
    [">" <> content, ..rest] ->
      case format(string.trim(content)) {
        Ok(format) ->
          lex_loop(
            rest,
            LexedRecipe(..recipe, formats: [format, ..recipe.formats]),
          )
        Error(InsufficientArguments) -> {
          io.println_error("Incorrect number of format arguments.
            Got: `>" <> content <> "`
            Expected: `> [name] [format string]`")
          lex_loop(rest, recipe)
        }
      }
    [_, ..rest] -> lex_loop(rest, recipe)
  }
}

fn headmatter(pair: String) -> Result(Headmatter, LexError) {
  case string.split_once(pair, on: " ") {
    Ok(#(name, data)) -> Ok(Headmatter(key: name, value: data))
    Error(Nil) -> Error(InsufficientArguments)
  }
}

fn format(pair: String) -> Result(Format, LexError) {
  case string.split_once(pair, on: " ") {
    Ok(#(name, data)) -> Ok(Format(name: name, template: data))
    Error(Nil) -> Error(InsufficientArguments)
  }
}
