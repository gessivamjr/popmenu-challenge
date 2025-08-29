# Overview

This application is a Restaurants platform MVP, it allows user to store and query restaurants, menus and dishes data, it also counts with a file processing feature that enables uploading a JSON file containing all the data you need in the platform to be processed at once, the records are logged into a specific log file, `log/restaurant_import.log`.

It is built with Ruby on Rails 8, using it's own features such as ActiveStorage and SolidQueue, and it's backed by a SQLite database.

---

### How to run it

> System requirements:
> - Ruby 3.3.5 installed
> - Git

1. Clone the repository with `git@github.com:gessivamjr/popmenu-challenge.git` in the directory of your choice
2. Then move to the directory and run in your terminal the command `bundle install` to install all dependecies
3. Next you need to run `bin/rails db:setup`, this command will create the database, load the schema and already seed it with some records
4. Finally, run `bin/rails server` in a terminal and `bin/jobs start` in another. This will start the application and SolidQueue to enable processing background jobs

---

### Running tests

If you already installed all the dependencies with `bundle install`, your system has RSpec available to execute the unit tests placed under the `spec/` directory.

Run `bundle exec rspec` to run all of them.

---

### Endpoints

For detailed API documentation including all available endpoints, request/response examples, and parameter specifications, see [API_DOCUMENTATION.md](./API_DOCUMENTATION.md).

---

### Technical choices

To build this application, i chose a lightweight stack thinking about what would be easier to the person who will run it. 
- SQLite: is a practical choice for a database, it does not require a separate process to be running, you can see all the data in a single file, so no need of a database management tool and also it doesn't need any previous configuration, all of that without losing ACID support and performance.
- ActiveStorage locally: it follows the same logic as SQLite, it doesn't need any extra software running simultaneously, any extra configuration to who will run it and it suits a MVP with low disk usage.
- SolidQueue: it leverages the SQLite database already installed, gives visibility without extra work in the database and Rails offers a lot of personalized configuration to manage queues, number of threads, retries, logs etc.
- Logging locally: besides the amount of storage that logs can take easily, i started this app logging locally, pointing to a specific file, in order to keep things managed in the application.

---

### Next Steps

You can think that this is a too simple solution for development, so alternatively you can think about introducing more robusts services, such as: 
1. PostgreSQL as database.
2. ActiveStorage pointing to a scalable storage service, AWS S3, Azure Storage, Google Cloud Storage, MinIO or many others, all of them will have a large free tier usage.
3. Setting up Redis + Sidekiq, which is a very common solution to processing background jobs.
4. Connecting an external log service, Axiom would be a good choice with a large free tier for example, because you can maintain grepable capabilities having now visual interface, and of course you remove the liability of logging and consuming the storage of the machine for a chosen availability time range.
5. Docker compose to manage all of those services in local containers