# Ripper Locals

A Ripper-based parser to determine the local variables in a method. Find locals from:

- Method parameters
- Local assigns
- Exclude block-scoped locals

## Example

```ruby
# locals: a, b, c, d, e, f
def do_stuff(a, *b)
  c = a + b
  x.each { |y| z = y }
  d = c + 1
  e, *f = d
end
```

See `test.rb` for more.

## Develop

- Deps: `gem install minitest`
- Tests: `ruby test.rb`
