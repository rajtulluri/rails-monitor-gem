# health-monitor-rails



This is a health monitoring Rails mountable plug-in, which checks various services (db, cache, sidekiq, redis, etc.).

Mounting this gem will add a '/check' route to your application, which can be used for health monitoring the application and its various services. The method will return an appropriate HTTP status as well as an HTML/JSON/XML response representing the state of each provider.

You can filter which checks to run by passing a parameter called ```providers```.


### JSON Response

```bash
>> curl -s http://localhost:3000/check.json | json_pp
```

### Filtered JSON Response

```bash
>> curl -s http://localhost:3000/check.json?providers[]=database&providers[]=redis | json_pp
```



### XML Response

```bash
>> curl -s http://localhost:3000/check.xml
```

### Filtered XML Response

```bash
>> curl -s http://localhost:3000/check.xml?providers[]=database&providers[]=redis
```

## Setup

If you are using bundler add health-monitor-rails to your Gemfile:

```ruby
gem 'health-monitor-rails'
```

Then run:

```bash
bundle install
```

Otherwise, install the gem:

```bash
gem install health-monitor-rails
```

## Usage

You can mount this inside your app routes by adding this to config/routes.rb:

```ruby
mount HealthMonitor::Engine, at: '/'
```

## Supported Service Providers

The following services are currently supported:

* Database (through active records)
* Cache
* Redis
* Resque
* Rails app

## Configuration

### Adding Providers

By default, only the database check is enabled. You can add more service providers by explicitly enabling them via an initializer:

```ruby
HealthMonitor.configure do |config|
  config.cache
  config.redis
  config.sql
  config.rail_gun
  config.resque
end
```

### Provider Configuration

Some of the providers can also accept additional configuration:

```ruby
# Redis
HealthMonitor.configure do |config|
  config.redis.configure do |redis_config|
    redis_config.connection = ['localhost:6379', 'xx.xx.xx.xx:xxxx'] # A list of sockets
  end
end

```

```ruby
# Rails app
HealthMonitor.configure do |config|
  config.redis.configure do |rails_config|
    rails_config.url = ['http://localhost:3000'] # A list of urls
  end
end
```

The currently supported settings are:


#### Redis

* `connection`: Use custom Redis host and port

### Adding a Custom Provider

It's also possible to add custom health check providers suited for your needs (of course, it's highly appreciated and encouraged if you'd contribute useful providers to the project).

To add a custom provider, you'd need to:

* Implement the `HealthMonitor::Providers::Base` class and its `check!` method (a check is considered as failed if it raises an exception):

```ruby
class CustomProvider < HealthMonitor::Providers::Base
  def check!
    raise 'Oh oh!'
  end
end
```

* Add its class to the configuration:

```ruby
HealthMonitor.configure do |config|
  config.add_custom_provider(CustomProvider)
end
```

### Adding a Custom Error Callback

If you need to perform any additional error handling (for example, for additional error reporting), you can configure a custom error callback:

```ruby
HealthMonitor.configure do |config|
  config.error_callback = proc do |e|
    logger.error "Health check failed with: #{e.message}"

    Raven.capture_exception(e)
  end
end
```

### Adding Authentication Credentials

By default, the `/check` endpoint is not authenticated and is available to any user. You can authenticate using HTTP Basic Auth by providing authentication credentials:

```ruby
HealthMonitor.configure do |config|
  config.basic_auth_credentials = {
    username: 'SECRET_NAME',
    password: 'Shhhhh!!!'
  }
end
```

### Adding Environment Variables

By default, environment variables are `nil`, so if you'd want to include additional parameters in the results JSON, all you need is to provide a `Hash` with your custom environment variables:

```ruby
HealthMonitor.configure do |config|
  config.environment_variables = {
    build_number: 'BUILD_NUMBER',
    git_sha: 'GIT_SHA'
  }
end
```

## License

The MIT License (MIT)

Copyright (c) 2017

Permission is hereby granted, free of charge, to any person obtaining a copy of
this software and associated documentation files (the "Software"), to deal in
the Software without restriction, including without limitation the rights to
use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of
the Software, and to permit persons to whom the Software is furnished to do so,
subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
FOR A PARTICULAR PURPOSE AND NON-INFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
