# Doc Yo Self

An auto documentation for Rails. Pop it into your test suite and watch it amaze.

Time for this project was provided by my employer, [SmashingBoxes](http://smashingboxes.com/). What a great place to work.


## Setup

In your gemfile:
`gem 'doc_yo_self', github: 'elfassy/doc_yo_self', group: :test`

In  `test_helper.rb`:
```ruby
DocYoSelf.config do |c|
  c.template_file = 'test/template.md.erb'
  c.output_folder   = 'wiki'
end
```

See test/fake_template.md for template examples.

To run doc generation after every controller spec, put this into your `teardown` method. Or whatever method your test framework of choice will run after *every test*.

## For Minitest Folks


At the bottom of your `test_helper.rb`:

```ruby
Minitest.after_run { DocYoSelf.finish! }
```

Then

```ruby
def test_some_api
  get :index, :users
  assert response.status == 200
  DocYoSelf.run!(self)
end
```
or have it run for all tests (recommended! You can skip! the ones you don't need)

```ruby
  def setup
    @doc_yo_self = DocYoSelf.new
  end

  def teardown
    @doc_yo_self.run!(self)
  end
```



## Options

Options can be passed as a hash to the `run!` function or directly to the instance methods:

### Adding notes
Defaults to the test name. Useful if you'd like to customize the text in your the output docs.
```ruby
def test_some_api
  # ...
  @doc_yo_self.note =  "This is fun"
  # or DocYoSelf.run!(self, note: "This is fun")
end
```

### Output file
Defaults to the test class name. This is the name of the file in which *this* test will be added.
```ruby
def test_some_api
  # ...
  @doc_yo_self.file = "fun.md"
end
```

### Response and Request
Defaults to `response` and `request` . 
```ruby
def test_some_api
  # ...
  @doc_yo_self.response = response
end
```

### skip!
You can easily skip a test with
```ruby
def test_some_api
  @doc_yo_self.skip!
  get :index, :users
  assert response.status == 200
end
```
