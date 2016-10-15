" author: Marcin Szamotulski

if (!exists("s:jobs"))
  let s:jobs = []
endif

fun! s:ExitJob(job, exitStatus)
    echomsg a:job . " exited with " . a:exitStatus
    let s:jobs = filter(s:jobs, {key, val -> val["job"] != a:job})
endfun

fun! JobLogHandler(ch, msg)
  let jobs = filter(copy(s:jobs), {key, val -> val["job"] == ch_getjob(a:ch)})
  if (len(jobs) != 1)
    echoerr "JobLogHandler: found " . len(jobs)
    return
  endif
  let log = get(jobs[0], "log", [])
  if !has_key(jobs[0], "log")
    let jobs[0]["log"] = log
  endif
  call add(log, substitute(a:msg, '[\d\+\w', "", "g")) 
endfun

fun! s:Job(bang, cmd)
  " vim checks if job finished every 10seconds, that's a bit long, but that's
  " the simplest solution for now
  let opts = {"exit_cb": function("s:ExitJob")}
  if a:bang != "!"
    let opts["out_cb"] = "JobLogHandler"
    let opts["err_cb"] = "JobLogHandler"
  endif
  let job = job_start(["sh", "-c", a:cmd], opts)
  call add(s:jobs, {"job": job, "cmd": a:cmd})
endfun

fun! s:ListJobs()
  let idx = 0
  for job in s:jobs
    let padding = join(map(range(max([2, 25 - len(job["cmd"])])), {-> " "}), "")
    echomsg printf("%3d %s%s %s", idx, job["cmd"], padding, job["job"])
    let idx = idx + 1
  endfor
endfun

fun! s:LogJob(bang, name)
  if a:name =~ '^\s*-\?\s*\d\+\s*$'
    let job = s:jobs[max([0, min([str2nr(a:name), len(s:jobs) - 1])])]
  elseif len(a:name)
    let match = 0
    for job in s:jobs
      if match(job["cmd"], a:name) != -1
	let match = 1
	break
      endif
    endfor
    if !match
      echohl WarningMsg
      echo "no job matched"
      echohl Normal
      return
    endif
  else
    let job = s:jobs[len(s:jobs) - 1]
  endif
  if !exists("job")
    return
  endif

  echo join(get(job, "log", []), "\n")
  if a:bang == "!"
    let job["log"] = []
  endif
endfun

command! -nargs=+ -bang -complete=shellcmd Job call s:Job('<bang>', '<args>')
command! -count=99999 HaltJob call job_stop(remove(s:jobs, '<count>' == 99999 ? len(s:jobs) - 1 : '<count>')["job"])
command! ListJobs call s:ListJobs()
command! -nargs=* -bang LogJob call s:LogJob('<bang>', '<args>')
