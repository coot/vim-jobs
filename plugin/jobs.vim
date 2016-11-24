" author: Marcin Szamotulski

if (!exists("s:jobs"))
  let s:jobs = []
endif

fun! s:SilentExitJob(job, exitStatus)
    let s:jobs = filter(s:jobs, {key, val -> val["job"] != a:job})
endfun

fun! s:ExitJob(job, exitStatus)
    echomsg a:job . " exited with " . a:exitStatus
    call s:SilentExitJob(a:job, a:exitStatus)
endfun

fun! GetJob(ch)
  let jobs = filter(copy(s:jobs), {key, val -> val["job"] == ch_getjob(a:ch)})
  if len(jobs)
    return jobs[0]
  else
    return v:none
  endif
endfun

fun! LogJobHandler(ch, msg)
  let job = GetJob(a:ch)
  if (type(job) != v:t_dict)
    return
  endif
  let log = get(job, "log", [])
  call add(log, substitute(a:msg, '[\d\+\w', "", "g")) 
endfun

fun! Job(cmd, ...)
  " vim checks if job finished every 10seconds, that's a bit long, but that's
  " the simplest solution for now
  if a:0 && a:1 && !exists("*" . a:1)
    echoerr "E700: Unknown function: " . a:1
    return
  endif
  let opts = {}
  let inASilentWay = !(!a:0 || a:0 >= 1 && len(a:1)) " ;)
  let opts["exit_cb"] = !inASilentWay ? function("s:ExitJob") : function("s:SilentExitJob")
  if !inASilentWay
    let opts["out_cb"] = a:0 ? a:1 : "LogJobHandler"
    let opts["err_cb"] = a:0 ? a:1 : "LogJobHandler"
  endif
  let job = job_start(["sh", "-c", a:cmd], opts)
  call add(s:jobs, {"job": job, "cmd": a:cmd, "log": []})
endfun

fun! s:ListJobs()
  let idx = 0
  for job in s:jobs
    let padding = join(map(range(max([2, 25 - len(job["cmd"])])), {-> " "}), "")
    echomsg printf("%3d %s%s %s", idx, job["cmd"], padding, job["job"])
    let idx = idx + 1
  endfor
endfun

fun! s:LogJob(bang, lines, name)
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

  let log_list = get(job, "log", [])
  echo join(a:lines == 0 ? log_list : log_list[max([0,len(log_list) - a:lines]):], "\n")
  if a:bang == "!"
    let job["log"] = []
  endif
endfun

fun! s:HaltJobs(line1, line2, count)
  let jobsLen = len(s:jobs)
  if (jobsLen == 0)
    return
  endif

  if (a:line1 == 1 && a:count == 99999)
    let start = jobsLen - 1
    let stop = start
  else
    let start = max([0, a:line1])
    let stop = min([a:line2, jobsLen - 1])
  endif
  if (stop < start)
    let [start, stop] = [stop, start]
  endif
  for job in remove(s:jobs, start, stop)
    call job_stop(job["job"])
  endfor
endfun

command! -nargs=+ -bang -complete=shellcmd Job call Job('<args>', '<bang>' != '!' ? "LogJobHandler" : "")
command! -count=99999 HaltJob call s:HaltJobs('<line1>', '<line2>', '<count>')
command! ListJobs call s:ListJobs()
command! -nargs=* -bang -range=0 LogJob call s:LogJob('<bang>', '<line1>', '<args>')
