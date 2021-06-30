lang = 'de'
config = {
  'cpu'           : 1
  'prozess'       : 1
  'prozess_limit' : 1 #limit3
  'load'          : 1
  'ip'            : 1
  'date'          : 1
  'spotify'       : 1
}
translate = {
  'de': {
    'month'   : ["Jan","Feb","Mär","Apr","Mai","Jun","Jul","Sep","Okt","Nov","Dez"]
    'days'    : ["So","Mo","Di","Mi","Do","Fr","Sa"]
    'load'    : 'Akku: '
    'prozess' : ''
    'cpu'     : 'CPU: '
    'ip'      : 'PublicIP: '
    'playing' : "Aktuell läuft: "
  }
}
curLang = translate[lang]
spacer = " | "


update: (output, domEl) ->
# Uhr
########################################################################################
  if config.date
    today = new Date
    day = if today.getDate() < 10 then "0" + (today.getDate()) else today.getDate()
    day_t = curLang.days[today.getDay()]
    month = if today.getMonth() + 1 < 10 then "0" + (today.getMonth() + 1) else (today.getMonth() + 1)
    hour = if today.getHours() < 10 then "0" + (today.getHours()) else today.getHours()
    min = if today.getMinutes() < 10 then "0" + (today.getMinutes()) else today.getMinutes()
    now = if config.date then "#{day_t} #{day}.#{month} | #{hour}:#{min}" else ""
    $(domEl).find('.clock').html(now)

# Load
########################################################################################
  if config.load
    @run "pmset -g batt | grep -o '[0-9]*%'", (error, stdout, stderr) ->
      stdout = stdout.split('\n')
      text = curLang.load + stdout + spacer
      text = text.replace ",", ""
      $(domEl).find('.battery').html(text)
# CPU
########################################################################################
  if config.cpu
    @run "top -l 1 | grep -E '^CPU' | grep -Eo '[^[:space:]]+%' | head -1", (error, stdout, stderr) ->
      stdout = stdout.split('\n')
      text = curLang.cpu + stdout
      text = text.replace ",", ""
      $(domEl).find('.cpu').html(text)
# Prozess
########################################################################################
  if config.prozess
    @run "ps axro \"pid, %cpu, ucomm\" | awk 'FNR>1' | head -n #{config.prozess_limit} | awk '{ printf \"%5.1f%%,%s,%s\\n\", $2, $3, $1}'", (error, stdout, stderr) ->
      stdout = stdout.split('\n')
      table  = $(domEl).find('.prozess')

      renderProcess = (cpu, name, id) ->
        "<div class='wrapper'>" +
          "<span class='cpu_l'>#{cpu}</span>
          <span class='space'>|</span>
          <span class='cpu_n'>#{name}</span>" +
        "</div>"

      for process, i in stdout
        args = process.split(',')
        if i < "#{config.prozess_limit}"
          table.find(".col#{i+1}").html renderProcess(args...)
      
# Spotify
########################################################################################
  if config.spotify
    @run """read -r running <<<"$(ps -ef | grep \"MacOS/Spotify\" | grep -v \"grep\" | wc -l)" &&
  test $running != 0 &&
  IFS='|' read -r theArtist theName <<<"$(osascript <<<'tell application "Spotify"
          set theTrack to current track
          set theArtist to artist of theTrack
          set theName to name of theTrack
          return theArtist & "|" & theName
      end tell')" &&
  if [ -z "$theArtist" ]
  then
      echo ""
  else
      echo "$theArtist - $theName" || echo "Not Connected To Spotify"
  fi""", (error, stdout, stderr) ->
      stdout = stdout.split('\n')
      if stdout.length > 1
      # && stdout.indexOf('unexp') == -1
        text = curLang.playing + stdout
        text = text.replace ",", ""
        if text.indexOf("unexpected") < 1 && text.indexOf("execution") < 1
          $(domEl).find('.current_playing').html(text)
########################################################################################


afterRender: (domEl) ->
# PublicIP
########################################################################################
  if config.ip
    @run "curl -s checkip.dyndns.org|sed -e 's/.*Current IP Address: //' -e 's/<.*$//'", (error, stdout, stderr) ->
      stdout = stdout.split('\n')
      text = curLang.ip + stdout + spacer
      text = text.replace ",", ""
      $(domEl).find('.public_ip').html(text)
########################################################################################




########################################################################################
# the refresh frequency in milliseconds
########################################################################################
refreshFrequency: 5000


########################################################################################
# LAYOUT
########################################################################################
render: (output) -> """
  <div class="row row_style">
    <span class="public_ip"></span>
    <span class="battery"></span>
    <span class="cpu"></span>
  </div>
  <div class="row row_style">
    <table class="prozess">
      <tr>
        <td class='col1'></td>
        <td class='col2'></td>
        <td class='col3'></td>
      </tr>
    </table>
  </div>
  <div class="row row_raw">
    <div>
      <h1 class="clock"></h1>
    </div>
  </div>
  <div class="row row_style">
    <div class="current_playing"></div>
  </div>
"""

########################################################################################
# STYLING
########################################################################################
style: """
  color: #FFFFFF
  font-family: Helvetica Neue
  bottom: 5px
  left: 5px
  background-color: rgba(0,0,0,.3)
  border-radius: 15px
  padding: 10px

  .row.row_style
    *
      text-shadow: 1px 1px 1px rgba(0,0,0,.5)
      font-size: 24px
      font-weight: 100
    .cpu 
      min-width: 110px

  h1
    font-size: 5em
    font-weight: 100
    margin: 0
    padding: 0

  table
    padding: 0
    background-color: rgba(0,0,0,.5)
    width: 100%

    td
      padding: 0
      font-size: 24px
      overflow: ellipsis
      text-shadow: 0 0 1px rgba(#000, 0.5)

    .wrapper
      padding: 5px
      position: relative

      *
        font-size: 20px!important
        display: inline-block 
        margin: 0
        font-weight: normal
        color: #ddd
        text-shadow: none
  """
