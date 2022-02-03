# Denmark

> Something is rotten in the state of Denmark.<br />
> -- *Horatio* in Shakespeare's Hamlet

I'm sure you've had the experience of evaluating modules on the Puppet Forge. Maybe
you were comparing a handful that all claimed to meet your needs, or maybe you were
just determining whether a specific module met your standards for deploying into
your production environment.

How did you go about it? You probably

* Skimmed the module's README for signs of the author's diligence.
* Poked through the issue list and pull requests on the repository hosting the module
  source to see how responsive the maintainers were to community collaboration.
* Checked the changelog for consistency.
* Maybe you even checked the commit history to see if there were unreleased fixes, or
  compared tags against the published version(s).

Wouldn't it be nice to automate some of this due diligence? That's what `denmark` does.
The Shakespeare quote refers to corruption at the top of a political hierarchy making
its way down through the entire state. In the context of this tool, it means that often
we can detect concerns with a project by sniffing around the edges and seeing if anything
rolling downhill stinks.

⚠️⚠️⚠️ ***Warning:** This is a very early release. It will be some time before the smell checks
it does are actually representative of the things you should be concerned about.*


## Overview

Denmark takes the name of a module, then extracts information from the Forge and from
the repository server hosting the module's source. This means that it relies on the
module to have an accurate `source` or `project_page` key set in its `metadata.json`.
Denmark currently supports both GitHub and GitLab source repositories.

Running Denmark will generate a report on your terminal of things you should look into.
Of course, if you'd like to integrate it into other tooling, it's also got JSON output.

```
$ denmark smell binford2k-node_encrypt --detail

[RED] alerts:
  The version released on the Forge does not match the version in the repository.
    > Validate that the Forge release is not compromised and is the latest released version.

[YELLOW] alerts:
  60% of the issues in this module's repository are more than 3 years old.
    > Many very old issues may indicate that the maintainer is not responding to community feedback.
  The version released on the Forge does not match the latest tag in the repo.
    > This sometimes just indicates sloppy release practices, but could indicate a compromised Forge release.
  The module was not published to the Forge on the same day that the latest release was tagged.
    > This sometimes just indicates sloppy release practices, but could indicate a compromised Forge release.

[GREEN] alerts:
  There was a gap of at least a year between the last two releases.
    > A large gap between releases often shows sporadic maintenance. This is not always bad.
```

As you can see, I've got some sloppiness issues on my module that I should go clean up!
Turns out that I'd built and published the module locally, but forgot to push and tag my
changes.


## Installation

Denmark is shipped as a standard RubyGem.

```
$ gem install denmark
```


## Configuration

GitHub allows anonymous rate-limited access to its API. If you're just evaluating a single
module, you can just use this tool, as long as the module source is on GitHub. If you're
evaluating many modules or any modules with their source on GitLab, you'll need tokens:

### `~/.config/denmark.yaml`
``` yaml
---
:gitlab:
  :token: <token>
:github:
  :token: <token>
```

See these pages for instructions on generating tokens:

* [GitHub](https://help.github.com/en/articles/creating-a-personal-access-token-for-the-command-line)
* [GitLab](https://docs.gitlab.com/ee/user/profile/personal_access_tokens.html)


## Contributing

Denmark keeps individual smell tests in plugin files in the `lib/denmark/plugins/` directory.
See the existing plugins for examples of the existing tests.

Start by copying the skeleton file below into a new plugin source file. This
should be a Ruby file that lives in `lib/denmark/plugins/` and defines a single
class named after its filename. For example, if you wanted to write a plugin to
analyze the readability of the README file, you might create the class
`Dropsonde::Metrics::Readme` in the Ruby file named `lib/denmark/plugins/readme.rb`.

Hooks are defined as a series of class methods and each of them is documented
below. Flesh each method out as needed.

``` ruby
class Denmark::Plugins::Demo
  def self.description
    # Return a string explaining what this smell test evaluates.
  end

  def self.setup
    # run just before generating this metric. Seldom used.
  end

  @param mod The Puppet module object returned from the Forge API
  @param repo An object representing the git repository. See below for abstraction details
  @returns Array[Hash] Test outputs to be merged into the combined report.
  def self.run(mod, repo)
    # return an array of hashes representing the data to be merged into the combined report.
    # See below for the API.
  end

  def self.cleanup
    # run just after generating this metric. Seldom used.
  end
end

```

### Plugin return value

Your plugin should return an array of hashes representing the smells discovered. You must
return an array, even if it's empty. It should look like so:

``` ruby
[
    {
        severity: :orange,
        message: "The warning message.",
        explanation: "A longform explanation of why this could be a problem. This is displayed when --detail is used.",
    },
]
```

#### Severity levels

* `:red`: The most severe level. This is almost certainly a problem and must be investigated.
* `:orage`
* `:yellow`
* `:green`: The least severe level. Mostly informational, but you should know about it.

#### Repository abstraction

The `Denmark::Repository` object is a _very_ thin wrapper around the GitHub and GitLab APIs.
It abstracts slight differences between the APIs and adds some helper methods to make it
simpler to do common things like load the contents of a file. See the source of
[lib/denmark/repository.rb](lib/denmark/repository.rb) for the methods it exposes.

We've also extended the `Array` class with a `.percent_of` method. This allows you to quickly
identify the percentage of items in an array that match a condition you specify in a block.
For example, this snippet returns the integer percentage of the issues on a repo with no comments:

``` ruby
unanswered = repo.issues.percent_of {|i| i.comments == 0 }
```


## Limitations

This tool is extremely early in its development and the output API is not yet formally defined.
If you write tooling to use it, then make your tooling resilient to changes.


Contact
-------

community@puppet.com

