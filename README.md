# Vim plugin to run and manage async jobs

It's **depreciated**, use [vim-term](https://github.com/coot/vim-term).

```viml
:Job cmd
```
Run a vim job.  It is run through a shell.  The stdout and stderr are
redirected to a log.

```viml
:ListJobs
```
Lists running jobs

```viml
:[lines]LogJob idx|pattern
```
List log of a job with idx (0-based) or the first one that is matching the
pattern.  The pattern is matched against cmd argument of `:Job`.  if `[lines]`
count is given and non zero only last `lines` are showng.

```viml
:HaltJob [idx]
```
Halt job with [idx], by default the last job.
