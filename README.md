# Fine-Grained Authorization Implementation in SQL + Reddit FGA model

## Installation

* Install [`fda`](https://docs.feldera.com/reference/cli#installation).
* Configure `fda` to use either the Feldera online sandbox or a local
  Feldera instance.
  - To use the sandbox:
    ```
    export FELDERA_HOST=https://try.feldera.com`
    export FELDERA_API_KEY=<your_feldera_sandbox_api_key>
    ```

  - To use local Feldera instance:
    - install Feldera: https://docs.feldera.com/docker/#docker-quickstart
    - `export FELDERA_HOST=http://localhost:8080`

## Running the demo

```
./fga.bash
```

The script will use `fga` to create the pipeline, populate it with test data and
dump the list of derived authorization tuples in the `relationships` view.  You
should see output similar to this:

```
+--------------+-------------+-------------+
| subject_id   | resource_id | relation_id |
+--------------+-------------+-------------+
| u/specialmod | r/dogs      | can_view    |
| u/randomcontributor | r/random    | contributor |
| u/specialmod | r/dogs      | moderator   |
| u/catperson | r/cats      | can_view    |
| u/randomcontributor | r/random    | can_view    |
| u/catperson         | r/cats      | subscribed  |
| u/randomcontributor | 1234        | can_view    |
| r/random   | 1234        | subreddit   |
+------------+-------------+-------------+
```
