# SimpleDiscussion: A Powerful Forum Engine for Ruby on Rails

[![Build Status](https://github.com/circuitverse/simple_discussion/workflows/Tests/badge.svg)](https://github.com/circuitverse/simple_discussion/actions) [![Gem Version](https://badge.fury.io/rb/simple_discussion.svg)](https://badge.fury.io/rb/simple_discussion)

SimpleDiscussion is a comprehensive Rails forum gem, inspired by the [GoRails forum](https://gorails.com/forum). It's currently in production use by CircuitVerse, which you can see in action [here](https://circuitverse.org/forum).

![GoRails Forum Screenshot](https://d3vv6lp55qjaqc.cloudfront.net/items/3j2p3o1j0d1O0R1w2j1Y/Screen%20Shot%202017-08-08%20at%203.12.01%20PM.png?X-CloudApp-Visitor-Id=51470&v=d439dcae)

## Table of Contents

1. [Features](#features)
2. [Installation](#installation)
3. [Configuration](#configuration)
4. [Usage](#usage)
5. [Customization](#customization)
   - [Styling](#styling)
   - [Views and Controllers](#views-and-controllers)
6. [Advanced Features](#advanced-features)
   - [Markdown Editor](#markdown-editor)
   - [Profanity Check and Language Filter](#profanity-check-and-language-filter)
   - [Topic Search](#topic-search)
   - [Notifications](#notifications)
7. [Development](#development)
8. [Contributing](#contributing)
9. [License](#license)
10. [Code of Conduct](#code-of-conduct)

## Features

SimpleDiscussion offers a rich set of features to create a fully-functional forum:

- **Markdown Editor**: GitHub-like editor for posts and threads
- **Category Organization**: Easily categorize discussions
- **Moderation System**: Simple yet effective moderation tools
- **Spam Reporting**: Allow users to report spam
- **Thread Solving**: Mark threads as solved
- **Topic Search**: Built-in search functionality (can be overridable)
- **Notifications**: Email and Slack notifications
- **Customizable Styling**: Bootstrap v4 compatible out-of-the-box

## Installation

1. Add SimpleDiscussion to your Gemfile:

   ```ruby
   gem 'simple_discussion', github: "CircuitVerse/simple_discussion"
   ```

2. Install the gem:

   ```bash
   bundle install
   ```

3. Install and run migrations:

   ```bash
   rails simple_discussion:install:migrations
   rails db:migrate
   ```

4. Mount the engine in `config/routes.rb`:

   ```ruby
   mount SimpleDiscussion::Engine => "/forum"
   ```

5. Add the CSS to your `application.css`:

   ```scss
   *= require simple_discussion
   ```

## Configuration

1. Include SimpleDiscussion in your `User` model:

   ```ruby
   class User < ApplicationRecord
     include SimpleDiscussion::ForumUser

     def name
       "#{first_name} #{last_name}"
     end
   end
   ```

2. (Optional) Add a moderator flag to your `User` model:

   ```bash
   rails g migration AddModeratorToUsers moderator:boolean
   rails db:migrate
   ```

3. (Optional) Create an initializer file `config/initializers/simple_discussion.rb`:

   ```ruby
   SimpleDiscussion.setup do |config|
     config.profanity_filter = true # Default: true
     config.markdown_circuit_embed = false # Default: true
     config.markdown_user_tagging = false # Default: true
     config.markdown_video_embed = false # Default: true
     config.send_email_notifications = true # Default: true
     config.send_slack_notifications = false # Default: true
   end
   ```

## Usage

Add a link to the forum in your application's navbar:

```erb
<%= link_to "Forum", simple_discussion_path %>
```

## Customization

### Styling

To customize colors, create `simple_discussion_override_color.scss`:

```scss
$brand-color: #42b983;
$thread-solved-color: #42b983;
$thread-unsolved-color: #f29d38;
$button-background-color: #fff;
$button-hover-shadow-color: rgba(77, 219, 155, .5);
$link-active-color: #000;
$link-inactive-color: #555;
$forum-thread-filter-btn-link-hover-background: #f3f4f6;
```

Import this file before `simple_discussion` in your `application.scss`:

```scss
@import 'simple_discussion_override_color';
@import 'simple_discussion';
```

### Views and Controllers

To customize views or controllers:

```bash
rails g simple_discussion:views
rails g simple_discussion:controllers
rails g simple_discussion:helpers
```

## Advanced Features

### Markdown Editor

The Markdown Editor for drafting forum posts and threads is enabled by default. It includes extensions for embedding CircuitVerse Circuits, YouTube videos, and user tagging. These features can be toggled in the initializer.

### Profanity Check and Language Filter

Profanity checking and language filtering on forum posts are enabled by default. You can disable this feature in the initializer file.

### Topic Search

A basic implementation for searching across forum threads is included. You can enhance this by overriding the `ForumThread` model in your Rails application:

```ruby
class ForumThread < ApplicationRecord
  def self.search(query)
    ForumThread.joins(:forum_posts)
               .where("forum_threads.title LIKE :query OR forum_posts.body LIKE :query", query: "%#{query}%")
               .distinct
  end
end
```

For more advanced search capabilities, you can integrate with ElasticSearch, MilliSearch, or Postgres's FTS.

### Notifications

Email and Slack notifications can be configured in the initializer. For Slack notifications, set `simple_discussion_slack_url` in `config/secrets.yml`.

## Development

To set up the development environment:

1. Check out the repo
2. Run `bin/setup` to install dependencies
3. Run `rake test` to run the tests

## Contributing

We welcome bug reports and pull requests on GitHub at https://github.com/excid3/simple_discussion. Please adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.

## License

This gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).

## Code of Conduct

All contributors are expected to follow our [code of conduct](https://github.com/excid3/simple_discussion/blob/master/CODE_OF_CONDUCT.md).
