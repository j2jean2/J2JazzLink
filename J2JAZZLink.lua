
-- @J2JAZZLink
-- @version 1.0
-- @author Jean2
-- @about J2's Reaper script pour piloter JJAZZLab depuis Reaper>=7.72
--   
--


reaper.gmem_attach("J2JJazzLink")

if not reaper.ImGui_GetBuiltinPath then return reaper.ShowMessageBox('This script require ReaImGui extension','',0) end
package.path = reaper.ImGui_GetBuiltinPath() .. '/?.lua'
local ImGui = require 'imgui' '0.9.2'

local ctx = ImGui.CreateContext('J2JJazzLink')
local r = reaper


local premierpassage=true

local cache   = {}
local font = nil
local boutsize = 72
local bouth=33
local reload_font = false
local nolangue=1

local midioutitems=''
local midiinitems=''
local midiinnameslist={}
local midiinidlist={}
local jjMIDIINid=0

local numtrackjjmidi=-1
local numtrackjjaudio=-1
local numrackjjstarter=-1
local nomtrackjjinmidi=''
local nomtrackjjinaudio=''

--local jjmidiinarmed=false
--local jjaudioinarmed=false
local inputname="Waiting"

local niveaubase=-60  --(db)
local posnotestart=-1
local datestoprec=-1
local dureetimeout=4
local dureeattente=1   --1 seconde de mute pour éviter les bruits au recalage  

local midioutnameslist={}
local midioutidlist={}
local curmidioutJJcomsid=0
local curmidioutJJcomsidlindex=0

local filtermidichan=0  

local flagshowview=true
local nbmesparligne=8
local taillacc=2
local nbfutur=2
local decalagview=0
local flagnoprefix=false
local flagpistechords=false
local vieww=500
local viewh=120

local audiolatence=0.135
local midilatence=0.0087
local datefinrecallatencytry=0
  local nbessais=0
  local latencein=0
  local valmoy=0
  local sigma=0

local latenceval=0

local vstidrumtrackname='undef'
local bpm=120
local nommorceau=''
local codagejjazzinp='JJAZZIN'

local flagdebsetup=false
local flagenableshorts=true
local flagenablemidicmds=false
local flagsintercepteshorts=true
local flagdynposdansmorceau 
local flaglearnmidi=false
local inputshortboutselect=0
local inputshortboutbisselect=0
local tabjjcom={}
local kbactif=false
-----------------------------------variables initialisées via initvars() 
local flagjjestsurstop--=true
local flagreactivjjencours--=false
local datefinattente   --=0
local datetimeout      --=0
local structacaler     --=-1
local curmidinlinkcomid--=0
local curmidinlinkcomidlindex--=0
local lastinputsrc             --=-1   --ensuite 1 pour fluidsynth   2 pour midi  0 si flagJJlabisoff
local genjjaudioinputid       --=-1
local genjjmidiinputid        --=-1
local flagJJlabisoff--=nil
local flagforceJJlaboff--=true
local flagexistelivin--=false
local flagusecompens--=false

local jjstructure--={}
local durees--={}
local dureescum--={}
local nomsstruct--={}
local  strmesure--={}


local precstruct--=0
local mesureencours--=0
local structureencours--=1
local precplaypos--=-1
local preccurspos--=-1
local precdynposition--=0
local etatboucle--=0
local oldetatboucle--=0
local oldboucleactive--=false

local etatprojet--=-1
local structdebboucle--=0
local structfinboucle--=0
------------------------------------
local function initvars()

 lastinputsrc=-1   --ensuite 1 pour fluidsynth   2 pour midi  0 si flagJJlabisoff

 jjstructure={}
 durees={}
 dureescum={}
 nomsstruct={}
 strmesure={}
 genjjaudioinputid=-1
 genjjmidiinputid=-1
 structacaler=-1
 curmidinlinkcomid=0
 curmidinlinkcomidlindex=0
 flagreactivjjencours=false
 structacaler=-1
 flagjjestsurstop=true
 
 flagJJlabisoff=nil
 flagforceJJlaboff=true
 flagexistelivin=false
 
 flagusecompens=false
 datefinattente =0
 structureencours=1
 precplaypos=-1
 preccurspos=-1
 precdynposition=0
 precstruct=0
 mesureencours=0
 
 etatboucle=0
 oldetatboucle=0
 oldboucleactive=false
 etatprojet=-1
 structdebboucle=0
 structfinboucle=0

end
 ------------------
    local traduc={}
    traduc['TWO']=2
    traduc['THREE']=3
    traduc['FOUR']=4
    traduc['FIVE']=5
    traduc['SIX']=6
    traduc['SEVEN']=7
    traduc['EIGHT']=8
    traduc['TWELVE']=12
 -----------------------------------------------------Messages d'aide-
 helpmess={}
 
 
 helpmess['latencea']={[1]=[[Réglage de la latence d'arrivée du signal audio de Fluidsynth sortant de JJazzLab, qui arrive dans Reaper après un audio loopback, depuis l'ordre "Play" envoyé.
La valeur dépend de la config, et est assez variable, c'est une valeur moyenne (qui devrait se situer entre 0.1s et 0.15s) qui fera l'affaire.
Pour avoir la valeur de cette latence, mettre le décompte de JJazzLab en action, afin d'avoir le clic dans le signal.
Attention il vaut mieux éliminer la première valeur obtenue après certaines modifs dans JJazzLab, comme passer le precompte de On à Off ou inversément (elle est plus longue).
Dans ce cas, le mieux est donc de cliquer une fois sur "Estimate", de faire "Reset Stats" et de cliquer quelques fois sur "Estimate" pour obtenir une moyenne potable.
Saisir ensuite la moyenne obtenue.
Penser à remettre le décompte de JJazzLab sur Off ensuite 
 ]],
 [2]=[[Setting for the latency of the audio Fluidsynth's signal coming out of JJazzLab and reaching Reaper after an audio loopback. 
The value depends of the config, and is fluctuating, so an average value (moyenne, that should sit between 0.1s and 0.15s) can be used.
To get this value, set the JJazzLab's precount active, to get the click in the signal, and press the "estimate" button.
Warning : the first value obtained after certains changes in JJazzLab, like setting precount from On to Off or the contrary, is too high, and should be eliminated.
In that case, the best is to estimate one time, then click on "Reset Stats", and estimate again a few time to verify that the result is constant.
Then click a few times on the latency estimation button (no too speed), and read the average value. Then set up the value you read. 
Don't forget to set back the JJazzLab's precount to off after that.
 ]]
 }
 helpmess['latencem']={[1]=[[Réglage de la latence d'arrivée du clic produit par votre VSTI drum, jouant le signal MIDI de JJazzLab, depuis l'ordre "Play" envoyé. 
La valeur dépend de la config, et devrait être faible, qques ms, et constante.
Pour avoir la valeur de cette latence, mettre le décompte de JJazzLab en action, afin d'avoir le clic dans le signal, puis cliquer sur le bouton "Estimate"
Attention il vaut mieux éliminer la première valeur obtenue après certaines modifs dans JJazzLab, comme passer le precompte de On à Off ou inversément (elle est plus longue).
Dans ce cas, le mieux est donc de cliquer une fois, de faire "Reset Stats" et de recommencer quelques fois sur  "Estimate" pour vérifier que le résultat est ensuite bien constant.
Finalement, saisir ensuite la valeur obtenue.
Penser à remettre le décompte de JJazzLab sur Off ensuite, et à refaire un lancement "à blanc" avant d'avoir enfin la synchro des départs. 
  ]],
  [2]=[[Setting for the latency of the click emitted by your Drum VSTI receiving the JJazzLab's  MIDI signal.
The value depends of the config, and should be low, (a few ms) and constant.
To get this value, set the JJazzLab's precount active, to get the click in the signal, and press the "estimate" button.
Warning : the first value obtained after certains changes in JJazzLab, like setting precount from on to off or the contrary, is too high, and will not be the "good" one.
In that case, the best is to estimate one time, then click on "Reset Stats", and estimate again a few time to verify that the result is constant.
Then set up the value you read.
Don't forget to set back the JJazzLab's precount to off after that.
  ]]
  }
 helpmess['jjazzin']={[1]=[[J2JazzLink a besoin d'identifier 1 ou 2 track(s) qui recoivent le 
 signal live de JJazzLab ,entrée MIDI ou Audio stéréo (pour Fluidsynth)
Cela est fait en retrouvant une  sequence speciale 
de lettres dans leur nom. Par défaut, cette séquence 
est "JJAZZIN", et peut être modifiée ici]],
 
 [2]=[[J2JazzLink needs to identify 1 or 2 track(s) that receive the 
JJazzLab live signal, input MIDI or Audio stéréo (for Fluidsynth)
This is done by retreiving a special sequence of letters in the 
tracks names. The default is "JJAZZIN", and can be changed here]]}
 
 

 
 helpmess['KBshortc']={[1]=[[Pour editer les raccourcis :
Cliquer sur un bouton pour select/deselect
Cocher la case Learn
Entrer le raccourci voulu au clavier de l'ordi
Cliquer Delete ou touche Delete pour supprimer, of course.
 ]],
 [2]=[[To edit the shortcuts : 
Clic on a button to select deselect it 
Check the Learn Checkbox
Enter your shortcut via PC keyboard 
Click Delete or hit the Delete key to delete, sans blagues!]]}
 
 helpmess['Midicmds']={[1]=[[Pour editer les raccourcis :
Cliquer sur un bouton pour select/deselect
Cocher la case Learn
Envoyer la commande Midi voulue (NoteOn ou CChange)
Delete pour supprimer, of course.
 ]],
 [2]=[[To edit the shortcuts : 
Clic on a button to select/deselect
Check the Learn Checkbox
Enter your Midi command (NoteOn or  CChange) 
Click Delete to delete, sans blagues!]]}
 
 helpmess['JJMidicmds']={[1]=[[Commenecer par définir le Midi Out de Reaper (qui doit être le IN de JJazzLab)
Quelque chose comme "loopMIDIport1"
Vous pouvez modifier les notes, il faut les mêmes dans J2JazzLink et JJazzLab.
Le mieux est de ne rien toucher.
 ]],
 [2]=[[First, define the Midi Out from Reaper (it must be the IN for JJazzLab)
 Typically something like "loopMIDIport1"
You can then modify if needed the notes : they must be the same in J2JazzLink and JJazzLab
The simpliest is to stay with default settings on each
 ]]}
  helpmess['jazzlabisoff']={[1]=[[Cocher la case si la backing track de JJazzLab a été intégrée dans une piste de Reaper ]],
 
  [2]=[[Check the box if JJazzLab's backing track has been integrated in one track of Reaper ]]
 
 }
 helpmess['vstidrum']={[1]=[[Selectionner la piste du VSTI drum
 et cliquer sur le bouton SET]],
  
   [2]=[[Select the VSTI drum track , et click on the SET button]]
  }

 -----------------------------------------------------ImGui--------------------------------
  ---------------------------------------------------
 local function HSV(h, s, v, a)
   local r, g, b = ImGui.ColorConvertHSVtoRGB(h, s, v)
   return ImGui.ColorConvertDouble4ToU32(r, g, b, a or 1.0)
 end
 --------------------------------------------------------
 
 
 local couleurselect=0xFF00FFFF
  local couleurOK=0x00FFFFFF
  local  viewbgcolor= 0x1D72D3FF    
  local viewbgcolor2= 0x1127D9c8

 

 
local font = ImGui.CreateFont('sans-serif', 12)
 ImGui.Attach(ctx, font)
local font2 = ImGui.CreateFont('sans-serif', 14)
  ImGui.Attach(ctx, font2)
local font3 = ImGui.CreateFont('sans-serif', 16)
 ImGui.Attach(ctx, font3)
local font4 = ImGui.CreateFont('sans-serif', 20)
 ImGui.Attach(ctx, font4)
  local font5 = ImGui.CreateFont('sans-serif', 22)
   ImGui.Attach(ctx, font5)
  local fontes={font,font2,font3,font4,font5}
  
  local fontacc=fontes[2]
 local window_flags = ImGui.WindowFlags_None
 window_flags = window_flags | ImGui.WindowFlags_NoDocking  | ImGui.WindowFlags_NoScrollbar 
 --[[local window_flags = ImGui.WindowFlags_None
 
 --user config flags--
 if showBackgroung==false then window_flags = window_flags | ImGui.WindowFlags_NoBackground end
 if showOnTop then window_flags = window_flags | ImGui.WindowFlags_TopMost end
 
 --default flags--
 window_flags = window_flags | ImGui.WindowFlags_NoScrollWithMouse
 window_flags = window_flags | ImGui.WindowFlags_AlwaysAutoResize
 window_flags = window_flags |ImGui.WindowFlags_NoDecoration
 ]]
 
 ------------------------------------------------------------
 local function Get_Ruler_Lane_Count()   -- thanks to BuyOne for this function!
 -- since as of build 7.65 lane count isn't accessible via API
 -- the function uses a hack of creating a temp marker
 -- and force moving it to another lane starting from lane
 -- at index 100
 -- if lane at the destination index doesn't exist the marker
 -- is not moved and its original lane index remains the same,
 -- but it's moved as soon as a valid lane index is found
 -- and since the movement is attempted in reverse,
 -- the first lane index associated with successful movement
 -- will be the index of the last available lane
 
   -- only supported since build 7.62
   if tonumber(r.GetAppVersion():match('[%d%.]+')) < 7.62 then return end
 
 r.PreventUIRefresh(1)
 local index = r.AddProjectMarker(0, false, 0, 0, '', 0xFFFF) -- isrgn false, pos 0, rgnend 0, wantidx 0xFFFF, to be able to easily find it for deletion // insert temp marker
 local obj = r.GetRegionOrMarker(0, 0, '') -- index 0, guidStr empty
 r.SetRegionOrMarkerInfo_Value(0, obj, 'B_HIDDEN', 1) -- hide, although not strictly necessary thanks to PreventUIRefresh()
 local lane_idx_init = r.GetRegionOrMarkerInfo_Value(0, obj, 'I_LANENUMBER')
 local lane_count
   for i=100,0,-1 do
   r.SetRegionOrMarkerInfo_Value(0, obj, 'I_LANENUMBER', i)
   local lane_idx = r.GetRegionOrMarkerInfo_Value(0, obj, 'I_LANENUMBER')
     if lane_idx ~= lane_idx_init then
     -- if the very last lane is default for markers, the temp marker will be inserted there
     -- and during the loop will only be able to move to a lane at a lower index
     -- in which case fall back on the original lane index as the heighest
     lane_count = lane_idx < lane_idx_init and lane_idx_init or lane_idx
     break
     end
   end
 r.DeleteProjectMarker(0, index, false) -- isrgn false // delete temp marker
 --r.UpdateTimeline() -- required for proper UI update after change, but unnecessary due to PreventUIRefresh()
 r.PreventUIRefresh(-1)
 
 -- if there's one lane only the temp marker won't be able to move anywhere
 -- hence fall back on its original lane index
 return (lane_count or lane_idx_init)+1 -- +1 because lane index returned by GetRegionOrMarkerInfo_Value is 0-based
 
 end
 
 
 
 ------------------------------------------------------
 local function tableaujjcom()
 tabjjcom={}
  tabjjcom['play pause']={nom='play pause', note=24}     --les noms servent aussi de string dans exstate
   tabjjcom['prec']={nom='struc prec', note=25}
   tabjjcom['stop']= {nom='stop', note=26}
  tabjjcom['suiv']= {nom='struct suiv', note=27}
 tabjjcom['gotostart']= {nom='start', note=28}
   tabjjcom['play selection']= {nom='play selection', note=32}
    tabjjcom['loop']= {nom='loop', note=33}
 end
 ----------------------------------------------------
 local function  restorejjcomms() 
    tableaujjcom()
    for i,value in pairs(tabjjcom) do
     r.SetExtState('J2jjazzlink',tabjjcom[i].nom,tostring(tabjjcom[i].note),true) 
    end
 end
 ------------------------------------------------------
 local function sendjjcommand(xindx)
 if flagJJlabisoff then return end
 if curmidioutJJcomsid>-1 then
 xnote= tabjjcom[ xindx ].note
local strx=string.char(table.unpack({0x90,xnote,65}))
 reaper.SendMIDIMessageToHardware(curmidioutJJcomsid,strx)
 end
 end
 ------------------------------------------------
 
function log (t)
 reaper.ShowConsoleMsg(t .. '\n')
end
function blog (t)
 reaper.ShowConsoleMsg(tostring(t))
  reaper.ShowConsoleMsg(' ')
end
-----------------------------------------------------------
function logtable(table, indent)
  log(tostring(table))
  for index, value in pairs(table) do
    log('    ' .. tostring(index) .. ' : ' .. tostring(value))
  end
end
----------------------------------------------
function HelpMarker(desc)
  ImGui.Text(ctx, '(?)')
  if ImGui.BeginItemTooltip(ctx) then
    ImGui.PushTextWrapPos(ctx, ImGui.GetFontSize(ctx) * 35.0)
    ImGui.Text(ctx, desc)
    ImGui.PopTextWrapPos(ctx)
    ImGui.EndTooltip(ctx)
  end
end
-----------------------------------------------
local function EachEnum(enum)
  local enum_cache = cache[enum]
  if not enum_cache then
    enum_cache = {}
    cache[enum] = enum_cache

    for func_name, value in pairs(ImGui) do
      local enum_name = func_name:match(('^%s_(.+)$'):format(enum))
      if enum_name then
        enum_cache[#enum_cache + 1] = {value, enum_name}
      end
    end
    table.sort(enum_cache, function(a, b) return a[1] < b[1] end)
  end

  local i = 0
  return function()
    i = i + 1
    if not enum_cache[i] then return end
    return table.unpack(enum_cache[i])
  end
end
--------------------------------------------------------
local function GetNoteName(pitch)
    local notes = {"C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"}
    local octave = math.floor(pitch / 12) - 1 
    local note_idx = (pitch % 12) + 1
    return string.format("%s%d (%d)", notes[note_idx], octave, pitch)
end
----------------------------------------------------------------------
local  MsgTypes = { [8] = 'Note Off', [9] = 'Note On', [10] = 'Aftertouch', [11] = 'CC', [12] = 'Program Change', [13] = 'Channel Pressure', 
  [14] = 'Pitch Bend', [15] = 'SyEx' }
---------------------------------------------------------
--------------------------------
local mesboutons={
{nom='Play/Pause',couleur=HSV(0.4, 0.9, 0.7, 1.0),shortc=524,cha=1,typ=9,val1=24},
{nom='Stop',couleur=HSV(0.66, 0.8, 0.8, 1.0),shortc=612,cha=1,typ=9,val1=26},
{nom='Record',couleur=HSV(0.04, 0.9, 0.7, 1.0),shortc=-1,cha=-1,typ=9,val1=29},
{nom='GotoStart',couleur=HSV(0.792, 0.82, 0.925, 1.0),shortc=-1,cha=1,typ=9,val1=28},
{nom='Prev',couleur=HSV(0.565, 0.82, 0.925, 1.0),shortc=513,cha=1,typ=9,val1=25},
{nom='Next',couleur=HSV(0.6, 0.8, 0.8, 1.0),shortc=514,cha=1,typ=9,val1=27},
}
----------------------------------------------------   
 -- https://www.fhug.org.uk/wiki/wiki/doku.php?id=plugins:code_snippets:split_filename_in_to_path_filename_and_extension
    function SplitFilename(strFilename)
      -- Returns the Path, Filename, and Extension as 3 values
      return string.match(strFilename, "(.-)([^\\|/]-([^\\|/%.]+))$")
    end
 --------------------------------------------------------------------------
 
  function readAll(file)
     local f = io.open(file, "rb")
     local content = f:read("*all")
     f:close()
     return content
 end
 ------------------------------------------------------------------
 function checkinputformidicmds()
  prev_input_idx = prev_input_idx or 0
  local idx, buf, _, dev_id = reaper.MIDI_GetRecentInputEvent(0)
 local rep=-1
 if idx > prev_input_idx then
     local new_idx = idx
     local i = 0
    repeat
      if prev_input_idx ~= 0 and #buf == 3 then
      
       if curmidinlinkcomid == dev_id then
                 local msg1 = buf:byte(1)
                 local channel = (msg1 & 0x0F) + 1
                 local msg3 = buf:byte(3)
                 local typ = msg1>>4
            if (typ==9 and msg3>0) or typ==10 then
              local msg2 = buf:byte(2)
                for xnobout=1 , #mesboutons do
               if typ==mesboutons[xnobout].typ and channel==mesboutons[xnobout].cha and msg2==mesboutons[xnobout].val1 then
                 rep=xnobout
                end
               end
             end
          end
         end
         i = i + 1
         idx, buf, _, dev_id = reaper.MIDI_GetRecentInputEvent(i)
     until idx == prev_input_idx
    prev_input_idx = new_idx
  end
  return rep
 end
 -------------------------------------------------------------------------------------
 function GetMIDIInputbufs()
   -- local midi_table = {} --table plus utilisé ahora, gardé pour  ressource...
  
     prev_input_idx = prev_input_idx or 0
 
     local idx, buf, _, dev_id = reaper.MIDI_GetRecentInputEvent(0)
    
     if idx > prev_input_idx then
         local new_idx = idx
         local i = 0
         repeat
        --  if #buf>0  then print(#buf) end
             if prev_input_idx ~= 0 and #buf == 3 then
               local msg1 = buf:byte(1)
                     local channel = (msg1 & 0x0F) + 1
                     local typ = msg1>>4
                      local msg3 = buf:byte(3)
                    if ((typ==9 and msg3>0) or typ==10) and (channel==filtermidichan or filtermidichan==0) then
                        local msg2 = buf:byte(2)
                       return channel,typ,msg2
                        --midi_table[#midi_table+1] = {chan = channel,typ = typ, val1 = msg2,val2 = msg3, device = dev_id}
                    end
              end
             i = i + 1
             idx, buf, _, dev_id = reaper.MIDI_GetRecentInputEvent(i)
         until idx == prev_input_idx
 
         prev_input_idx = new_idx
     end
  return 0,0,0
 end
 ---------------------------------
 local function ayasignaldejjazz()
  local rep=true
  local nxinputsrc=-1
 if (r.GetInputActivityLevel(genjjaudioinputid)>niveaubase ) then 
     nxinputsrc=1
     elseif  (r.GetInputActivityLevel(genjjmidiinputid)>niveaubase )  then 
     nxinputsrc=2
     else rep=false
  end
  return rep,nxinputsrc
 end 
 --------------------------------------------
 local function cherchenotrack(nomt)
 local rep=-1
   local  count_all_tracks = reaper.CountTracks( 0 )
   for i = 0, count_all_tracks - 1 do
       local track = reaper.GetTrack(0, i)
       local rr, track_name = reaper.GetTrackName( track )
     if  string.find(track_name,nomt)  then   rep=i   break  end
  end
    return rep  
 end
 ---------------------------
 local function cherchefirstslecttrackname()
 local rep=''
   local  count_all_tracks = reaper.CountTracks( 0 )
   for i = 0, count_all_tracks - 1 do
   local track = reaper.GetTrack(0, i)
     if r.IsTrackSelected(track) then
        rr, rep = reaper.GetTrackName( track )
     break  end
   end
   return rep  
 end
 --------------------------------------------
 local function nomparam(ligne,codeparam)
 local nom
  local d, f= ligne:find(codeparam)
  if d then
  local protoval = string.sub(ligne,f+1)
  local finnom=protoval:find('"')
  nom = string.sub(protoval,1,finnom-1)
  end
 return nom
 end
 ------------------------------
 local function valeurparam(ligne,codeparam)
 local val
  local d, f= ligne:find(codeparam)
  if d then
    local protoval = string.sub(ligne,f,f+5)
    val=tonumber(string.match(protoval,'.(%d+).+'))
  end
 return val
 end
 -----------------------------------
 function decodesignature(rythmsignat)
-- rythmsignat="FIVE_FOUR"
local num,den=string.match(rythmsignat,'(%a+)[_](%a+)')
  num=traduc[num]
    den=traduc[den]
return num, den
  end
 -------------------------------------------------------
 local function valeurparent(xline)
 local val
  local d, f= xline:find('spItems/CLI__SectionImpl',plain)
  if f~=nil then
  local protoval = string.sub(xline,f+1,f+5)
    val=tonumber(string.match(protoval,'.(%d+).+'))
    end
 return val
 end
 -------------------
local function preparepistechords()
 local track = nil
 local numTracks = reaper.CountTracks(0)
 
   -- Search for existing "Chords" track
   for i = 0, numTracks - 1 do
     local t = reaper.GetTrack(0, i)
     local retval, name = reaper.GetSetMediaTrackInfo_String(t, "P_NAME", "", false)
     if name == "Chords" then
       track = t
       break
     end
   end
   if track~=nil then r.DeleteTrack(track) end
 --  if not track then
     -- Create new track at top
     reaper.InsertTrackAtIndex(0, true)
     track = reaper.GetTrack(0, 0)
     reaper.GetSetMediaTrackInfo_String(track, "P_NAME", "Chords", true)
     reaper.SetMediaTrackInfo_Value(track, "B_HEIGHTLOCK", 1)
 --  end
   
   reaper.Main_OnCommand(40297, 0) -- Unselect all tracks
   reaper.SetTrackSelected(track, true)

return track
end
------------------------------
local function prefixeur(delt)
  if flagnoprefix then
   if delt==0 then return ''
    else return ' '
    end
 else
  local pre1
  local pre2
  local ent=math.floor(delt)
  local dec=delt-ent
   if ent==0 then pre1=''
   elseif ent==1 then pre1='-'
   elseif ent==2 then pre1='--'
   elseif ent==3 then pre1='---'
   else pre1='----'
  end

  if dec>0.9 then pre2='-'
   elseif dec>0.70 then pre2='.,'
     elseif dec>0.6 then pre2=';;'
     elseif dec>0.4 then pre2='.'
      elseif dec>0.3 then pre2=';'
     elseif dec>0.15 then pre2=','
     else pre2=''
    end
 return pre1..pre2
 end
end
 ---------------------------------------
  
 --------------------------------------------------
 local function   faitstrings4mesuresdaff()
 strmesure={}
  local cummsg=''
 local mesprec=3
 local tt,qnprec,qnfinmesprec=r.TimeMap_GetMeasureInfo(0,3)
 local nomes
 
local nbtot=  r.GetNumRegionsOrMarkers(0) 
if nbtot>0 then 
 for i=0,nbtot-1 do 
  local obj = r.GetRegionOrMarker(0, i, '')
  
 if r.GetRegionOrMarkerInfo_Value(0, obj, 'I_LANENUMBER')==1 and  r.GetRegionOrMarkerInfo_Value(0, obj, 'B_ISREGION')==0  then
--if r.GetRegionOrMarkerInfo_Value(0, obj, 'I_LANENUMBER')==2 then
    local start= r.GetRegionOrMarkerInfo_Value(0, obj, 'D_STARTPOS')+0.01
   -- local long= r.GetRegionOrMarkerInfo_Value(0, obj, 'D_ENDPOS')-start
    local rv,string= r.GetSetRegionOrMarkerInfo_String(0, obj,'P_NAME', '', false)
    local qnacc= r.TimeMap_timeToQN(start)
  local qnaccprec =qnaccprec or qnacc 
  local mes= r.TimeMap_QNToMeasures(0, qnacc)
 --  blog('mes') log(mes)
 local tmes,qnmes,qnfinmes=reaper.TimeMap_GetMeasureInfo(0,mes-1)
-- blog('qnacc') log(qnacc)
--  blog('qnmes') log(qnmes)
   new= ( mes~=mesprec) 
          if new==false then     --on a un evt dans la précédente mesure
           cummsg=cummsg.. prefixeur(qnacc-qnprec)..string
          else
           strmesure[mesprec-3]=cummsg..prefixeur(qnfinmesprec-qnprec)
              local delta=mes-mesprec
                  if delta>1 then
                    for i=1,delta-1 do 
                     strmesure[mesprec-3+i]='.............'
                   end
                  end
                 cummsg=prefixeur(qnacc-qnmes)..string
            mesprec=mes
          end
         qnfinmesprec=qnfinmes
         qnprec=qnacc
 
         end
        end  --fin de for i=0,nbtot-1
   strmesure[mesprec-3]=cummsg
     local delt=dureescum[#jjstructure]-(mesprec-3)
     if delt>0 then 
     for i=1,delt do
      strmesure[mesprec-3+1]='..............'
      end
  end
  -- log(dureescum[#jjstructure])
   --log(mesprec-3)
  end --fin if nbtot>0
   strmesure[0]=''
 end
 -------------------------------------------
 --------------------------------------------------

 -------------------------------------------
  local function   amettextechords(nbparents,nbelts,tablacc,nbaccparent,numparentelt)
  
  r.PreventUIRefresh(1)
 if flagpistechords then   track=preparepistechords() end
 

 for istruct=1 , nbelts do
 local noparent=numparentelt[istruct]
  for noacc=1, nbaccparent[noparent] do
      local txt=tablacc[noparent][noacc].nomacc 
      -- log(txt)
     local xmes=dureescum[istruct]+tablacc[noparent][noacc].nomes+3
     local st,qn_start,qn_end= r.TimeMap_GetMeasureInfo(0,xmes)
     local xtemps=tablacc[noparent][noacc].notemps 
     local start=r.TimeMap2_QNToTime(0,qn_start+xtemps)
      local fin=r.TimeMap2_QNToTime(0,qn_end)
     if noacc<nbaccparent[noparent] then
       if tablacc[noparent][noacc].nomes ==tablacc[noparent][noacc+1].nomes then
       fin=r.TimeMap2_QNToTime(0,qn_start+tablacc[noparent][noacc+1].notemps ) 
      end
     end
     local length=fin-start
     
     local ProjectMarker= r.AddRegionOrMarker(0,false, start, 0,txt,-1,0)
     r.SetRegionOrMarkerInfo_Value(0, ProjectMarker, "I_LANENUMBER" , 1)   -----1=lane 2 si elle existe
     
     if flagpistechords then
        local item = reaper.AddMediaItemToTrack(track)
      reaper.SetMediaItemPosition(item, start, false)
      reaper.SetMediaItemLength(item, length, false)
      reaper.GetSetMediaItemInfo_String(item, "P_NOTES", txt, true)  
      end 
     
    end
  end
  
  r.PreventUIRefresh(-1)
  end
  -------------------------------------------
 local function  mettreimportdansregions(nbelts,Rhythmelement,coefftmpo,debelement,nbmesureselement,nomelement)
 
   if nbelts==0 then return   end
 
 reaper.Main_OnCommandEx( 42395, 1, 1)  --clear tempo envelope
     
local nbtot=  r.GetNumRegionsOrMarkers(0) 
 for i=nbtot-1,0,-1 do  
  local obj = r.GetRegionOrMarker(0, i, '') 
  local lane_idx= r.GetRegionOrMarkerInfo_Value(0, obj, 'I_LANENUMBER')
  if lane_idx==0 or  lane_idx==1  then r.DeleteProjectMarkerByIndex(0, i) end --
 end

local nbrullanes=Get_Ruler_Lane_Count()  
if nbrullanes<2 then  reaper.Main_OnCommandEx( 43541, 1, 1) end  -- créer lane(s)
if nbrullanes<3 then  reaper.Main_OnCommandEx( 43541, 1, 1) end    -->3
-- log( Get_Ruler_Lane_Count()  )
     local num,den= decodesignature( Rhythmelement[1])
    --   if den==8 and (num==6 or num==12) then TODO  quand on aura accès à la bpm basis de Reaper.....
     local rythmelementactu=Rhythmelement[1]
     reaper.SetTempoTimeSigMarker( 0, -1, 0, 0, 0, bpm, num, den, false )
     local debtime=r.TimeMap_GetMeasureInfo(0, 0)  --c'est un time
     local fintime=r.TimeMap_GetMeasureInfo(0, 3)
     local txt='JJazz'..nommorceau
 -- r.AddProjectMarker2(0, true, debtime,fintime , txt, 0, 0)
       local ProjectMarker= r.AddRegionOrMarker(0,true, debtime, fintime,txt,-1,0)
       r.SetRegionOrMarkerInfo_Value(0, ProjectMarker, "I_LANENUMBER" , 1)   -----1=lane 2
   -------------maintenant les vrais elements du morceau
  for i=1, nbelts do
    local debtime=r.TimeMap_GetMeasureInfo(0, debelement[i]+3)  --c'est un time
    local coeffrectif=1
   
       if Rhythmelement[i]~=rythmelementactu or  coefftmpo[i]~=coeffactu then
        local num,den= decodesignature( Rhythmelement[i])
          if den==8 and (num==6 or num==12) then coeffrectif=1.5 end  --workaround pour pallier absence de moyen de changer BPM base en noire pointée 
           rythmelementactu=Rhythmelement[i]
           coeffactu=coefftmpo[i]
           reaper.SetTempoTimeSigMarker( 0, -1, debtime, -1, -1, coeffrectif*coeffactu*bpm, num, den, false )
       end
    local fintime=r.TimeMap_GetMeasureInfo(0, debelement[i]+3+nbmesureselement[i])
    local ProjectMarker= r.AddRegionOrMarker(0,true, debtime, fintime, nomelement[i],-1,0)
    r.SetRegionOrMarkerInfo_Value(0, ProjectMarker, "I_LANENUMBER" , 0)   -----0=lane 1
   end
      reaper.UpdateArrange()
  end
  ----------------------------------------------------------
  ------------------------------
   local function faitdurees() --unité=mesures
   local     num_markers=#jjstructure
   dureescum={}
   for j=1 , num_markers do
     local qn=r.TimeMap2_timeToQN(0,jjstructure[j])
     dureescum[j]=r.TimeMap_QNToMeasures(0, qn)-4
   --  blog(' durcum') log ( dureescum[j])
   end
   durees={}
   for j=1 , num_markers-1 do
     durees[j]=dureescum[j+1]-dureescum[j]
   --     blog(' durj') blog(j) log (  durees[j])
    end
   end
   --------------------------------
   
   --------------------------------
   local function getjjstructure()
   jjstructure={}
   nomsstruct={}
   
 
      local nbtot=  r.GetNumRegionsOrMarkers(ReaProject0)
  if nbtot==0 then return end
    local lastrgn_end=0
  
     for j=0,nbtot-1 do
       local obj = r.GetRegionOrMarker(0, j, '') 
           local lane_idx= r.GetRegionOrMarkerInfo_Value(0, obj, 'I_LANENUMBER')
             local isregn= r.GetRegionOrMarkerInfo_Value(0, obj, 'B_ISREGION')
          local pos= r.GetRegionOrMarkerInfo_Value(0, obj, 'D_STARTPOS')
          local rgnend= r.GetRegionOrMarkerInfo_Value(0, obj, 'D_ENDPOS')
           local markrgnindexnumber= r.GetRegionOrMarkerInfo_Value(0, obj, 'I_INDEX')
         local rv,name= r.GetSetRegionOrMarkerInfo_String(0, obj,'P_NAME', '', false)
         
       if isregn  and string.sub(name,1,5) ~='JJazz' and lane_idx==0 then   --and markrgnindexnumber>0
     
     --  blog(j) log(lane_idx)
 --  log(name)
       nomsstruct[#nomsstruct+1]=name
     -- log(name)
        jjstructure[#jjstructure+1]=pos
   --     blog('#jjstructure') log(#jjstructure)
        lastrgn_end=rgnend
       end
     end
 jjstructure[#jjstructure+1]=lastrgn_end
  --    blog('#jjstructure') log(#jjstructure)    
    faitdurees() 
    faitstrings4mesuresdaff()
   end
  -----------------
  -------------------------------------------
  function aimporterJJAZZsng()  --modif pour chord track direct
  
       folder = reaper.GetExtState( "J2jjazzlink", "Folder" ) or ""
       retval, path = reaper.GetUserFileNameForRead(folder, "Open", ".sng" )
      
      if not retval then return -1 end
      
       
   local   debelement={}
  local    nomelement={}
  local     nbmesureselement={}
  local     Rhythmelement={}
   local    coefftmpo={}
   local    numparentelt={}
     local  tablacc={}
     local nbaccparent={}
  local     nbelts=0
 local      nbparents=0
  local     nbmesuresparent={}
  local nomacc
    local  folder, filename, ext = SplitFilename(path)
   --  midifileassocie=string.sub(path,1,string.len(path)-3)..'mid'
    -- log(midifileassocie)
     reaper.SetExtState( "J2jjazzlink", "Folder", folder, true )
      nommorceau=filename
     reaper.SetProjExtState(0, 'jjazzlinko', 'nommorceau', nommorceau)   
     -------------------------------- 
       content = readAll(path)
      -- Split Lines
      lines = {}
      for s in content:gmatch("[^\r\n]+") do
          table.insert(lines, s)
      end
  
      -------------------------------
      local tmpochangeonnextline=false
      for i, line in ipairs( lines ) do 
          local line = line:gsub(string.char(0), "")
          line = line:gsub("\n", "") 
       if line:find('</spSpts>') then break end
    -----------------------------------parents----------------------  
   if line:find('"CLI_SectionImplSP"') then
          nbparents=nbparents+1   tablacc[nbparents]={}
        --   blog('nbparents') log(nbparents)
         -- nbacc=0
          nbaccparent[nbparents]=0
          mesdebparent=valeurparam(line,'spBarIndex="')
         -- log (mesdebparent)
    elseif  line:find('"ExtChordSymbolSP"') then
        -- nbacc=nbacc+1
         nomacc=nomparam(line,'spName="')
        nbaccparent[nbparents]= nbaccparent[nbparents]+1
     --  blog(nbparents)  blog(nomacc) log( nbaccparent[nbparents])
      --  log( nbaccparent[nbparents])
        elseif   line:find('"PositionSP"') then
           local descrpos=nomparam(line,'spPos="')
           local pospoint,fpp= descrpos:find(':')
          local partg=string.sub(descrpos,2,pospoint-1)
           local partd=string.sub(descrpos,pospoint+1,string.len(descrpos)-1)
        
           local nomes=tonumber(partg)-mesdebparent
         -- log(nomes)
       local notemps
    local pospoint,fpp= partd:find(',') or -1
    if pospoint>0 then
    local partent= string.sub(partd,1,pospoint-1)
    local partdec= string.sub(partd,pospoint+1,string.len(partd))
   -- log(partent)
   -- log(partdec)
    notemps=tonumber(partent..'.'..partdec)
    else
     notemps=tonumber(partd)
    end 
  --  log(notemps)
      table.insert( tablacc[nbparents],{nomes=nomes,notemps=notemps,nomacc=nomacc})
    --  log(nomacc)
 end
  -- <spPos resolves-to="PositionSP" spVERSION="2" spPos="[0:1,33]"/>     
     ----------------------------éléments----------------------------------  
       if tmpochangeonnextline   then
     --  log(line)
     local coef100=tonumber(string.match(line,'<string>(%d+)</string>'))
     if coef100~=nil then  coefftmpo[nbelts]=coef100/100 end
         -- coefftmpo[nbelts]=tonumber(string.match(line,'<string>(%d+)</string>'))/100
          tmpochangeonnextline=false
          
       elseif line:find('rpTempoID') then tmpochangeonnextline=true
       elseif  line:find('spTempo="') then 
         --   nommorceau=nomparam(line,'spName="')  --pas fiable
        -- nommorceau=filename
            bpm=valeurparam(line,'spTempo="')
       elseif  line:find('<SongPartImpl') then
            nbelts=nbelts+1
           Rhythmelement[nbelts]=nomparam(line,'spRhythmTs="')
            nomelement[nbelts]=nomparam(line,'spName="')
            debelement[nbelts]=valeurparam(line,'spStartBarIndex="')
            nbmesureselement[nbelts]=valeurparam(line,'spNbBars="')
          elseif  line:find('<spParentSection class=') then
          numparentelt[nbelts]=valeurparent(line) or 1
         
     -- blog('numparent') log( numparentelt[nbelts])
            nbmesuresparent[ numparentelt[nbelts]]= nbmesureselement[nbelts]---moyen scabreux de connaître ce nombre de mesures du parent
     -- log( numparent[nbelts])
       end
      end
 
  
 -- local sortie=1
  if nbelts==0 or nbparents==0 then return 0 end
   mettreimportdansregions(nbelts,Rhythmelement,coefftmpo,debelement,nbmesureselement,nomelement)
     getjjstructure()
      amettextechords(nbparents,nbelts,tablacc,nbaccparent,numparentelt)
       reaper.Main_OnCommandEx( 43715, 1, 1)  --renumber by ruler lane
      
  return 1
  end
 -----------------------------
 
local function chargeexstatescript()

 if r.HasExtState('J2jjazzlink', "vstidrumtrackname") then 
 vstidrumtrackname = r.GetExtState('J2jjazzlink', "vstidrumtrackname") 
 end

 if r.HasExtState('J2jjazzlink', "curmidioutJJcomsid") then 
 curmidioutJJcomsid = tonumber(r.GetExtState('J2jjazzlink', "curmidioutJJcomsid")) 
 end
 if r.HasExtState('J2jjazzlink', "curmidinlinkcomid") then curmidinlinkcomid = tonumber(r.GetExtState('J2jjazzlink', "curmidinlinkcomid")) end
 
 if r.HasExtState('J2jjazzlink', "audiolatence") then audiolatence = tonumber(r.GetExtState('J2jjazzlink', "audiolatence")) end
  if r.HasExtState('J2jjazzlink', "midilatence") then midilatence = tonumber(r.GetExtState('J2jjazzlink', "midilatence")) end

 
 
 if r.HasExtState('J2jjazzlink', "flagpistechords") then flagpistechords = r.GetExtState('J2jjazzlink', "flagpistechords")=='true' end
if r.HasExtState('J2jjazzlink', "flagenableshorts") then flagenableshorts = r.GetExtState('J2jjazzlink', "flagenableshorts")=='true' end
  if r.HasExtState('J2jjazzlink', "flagsintercepteshorts") then flagsintercepteshorts = r.GetExtState('J2jjazzlink', "flagsintercepteshorts")=='true' end
  if r.HasExtState('J2jjazzlink', "flagenablemidicmds") then flagenablemidicmds = r.GetExtState('J2jjazzlink', "flagenablemidicmds")=='true' end
   if r.HasExtState('J2jjazzlink', "nolangue") then nolangue = tonumber(r.GetExtState('J2jjazzlink', "nolangue")) end

  for i=1,#mesboutons do
  if r.HasExtState('J2jjazzlink', 'boutonshortcut'..tostring(i)) then 
  mesboutons[i].shortc = tonumber(r.GetExtState('J2jjazzlink','boutonshortcut'..tostring(i))) end 
  if r.HasExtState('J2jjazzlink', 'boutonsmidityp'..tostring(i)) then 
  mesboutons[i].typ = tonumber(r.GetExtState('J2jjazzlink','boutonsmidityp'..tostring(i))) end 
  if r.HasExtState('J2jjazzlink', 'boutonsmidicha'..tostring(i)) then 
  mesboutons[i].cha = tonumber(r.GetExtState('J2jjazzlink','boutonsmidicha'..tostring(i))) end 
  if r.HasExtState('J2jjazzlink', 'boutonsmidival1'..tostring(i)) then 
  mesboutons[i].val1 = tonumber(r.GetExtState('J2jjazzlink','boutonsmidival1'..tostring(i))) end 
  end
 
 tableaujjcom()
  for i,value in pairs(tabjjcom) do
      if r.HasExtState('J2jjazzlink',tabjjcom[i].nom) then 
      tabjjcom[i].note = tonumber(r.GetExtState('J2jjazzlink',tabjjcom[i].nom)) end  
  end
   reaper.gmem_write(11, tabjjcom['play pause'].note) 
end

--------------------------------------------------------
local function chargeprojectexstate()
 
  local exists, sindex = reaper.GetProjExtState(0, 'jjazzlinko',  'nommorceau')
  if exists ~= 0 then nommorceau = sindex end
  

  
  local exists, sindex = reaper.GetProjExtState(0, 'jjazzlinko',  'codagejjazzinp')
  if exists ~= 0 then codagejjazzinp = sindex end
  
  local exists, sindex = reaper.GetProjExtState(0, 'jjazzlinko',  'flagshowview')
   if exists ~= 0 then   flagshowview =(sindex=='true') end
   
   local exists, sindex = reaper.GetProjExtState(0, 'jjazzlinko',  'flagforceJJlaboff')
    if exists ~= 0 then   flagforceJJlaboff =(sindex=='true') end
    
    local exists, sindex = reaper.GetProjExtState(0, 'jjazzlinko',  'nbmesparligne')
     if exists ~= 0 then   nbmesparligne =tonumber(sindex) end
     
     local exists, sindex = reaper.GetProjExtState(0, 'jjazzlinko',  'taillacc')
      if exists ~= 0 then   taillacc =tonumber(sindex) end
      
      
  local exists, sindex = reaper.GetProjExtState(0, 'jjazzlinko',  'nbfutur')
 if exists ~= 0 then   nbfutur =tonumber(sindex) end
 
 local exists, sindex = reaper.GetProjExtState(0, 'jjazzlinko',  'flagnoprefix')
  if exists ~= 0 then   flagnoprefix =(sindex=='true') end
  
       
   local exists, sindex = reaper.GetProjExtState(0, 'jjazzlinko',  'decalagview')
  if exists ~= 0 then   decalagview =tonumber(sindex) end
  
  local exists, sindex = reaper.GetProjExtState(0, 'jjazzlinko',  'vieww')
  if exists ~= 0 then   vieww =tonumber(sindex) end
  
  local exists, sindex = reaper.GetProjExtState(0, 'jjazzlinko',  'viewh')
  if exists ~= 0 then   viewh =tonumber(sindex) end

 
  
end
---------------------------

--local function atrackinfoview() --utilitaire

-- faitstrings4mesuresdaff()
 
-- end
--[[ 
for i=1, 255 do
blog(i) blog(' ') log(utf8.char(i))
if utf8.char(i)=='.' then log('hghhhjgkssssssssss') end
end

  local  count_all_tracks = reaper.CountTracks( 0 )
  for i = 0, count_all_tracks - 1 do
    local track = reaper.GetTrack(0, i)
    if r.IsTrackSelected(track) then
      local rr, track_name = reaper.GetTrackName( track )
       log(track_name)
       log(r.GetTrackNumSends(track, -1))
       
  local rv,rname=     r.GetTrackReceiveName(track, 0)
 --local nbitems=  r.CountTrackMediaItems(track) 
  if rv then log(rname) end
-- local  item=r.GetTrackMediaItem(track, 0)
 --  r.SetMediaItemSelected(item, true)
 -- local take = r.GetActiveTake(item)    
  end
 end
reaper.UpdateArrange()
]]
---------------------------------------------------------------------
local function muteunmuteinJJ(valmute)

checkinputformidicmds()  --pour vidage
 if numtrackjjmidi>-1 then
     local track = reaper.GetTrack(0, numtrackjjmidi)
     if reaper.GetMediaTrackInfo_Value(track,"I_RECARM")==1 then
         --  log(track_name)
          reaper.SetMediaTrackInfo_Value(track,"B_MUTE",valmute)
     end
  end
  if numtrackjjaudio>-1 then
     local track = reaper.GetTrack(0, numtrackjjaudio)
     if reaper.GetMediaTrackInfo_Value(track,"I_RECARM")==1 then
         --  log(track_name)
          reaper.SetMediaTrackInfo_Value(track,"B_MUTE",valmute)
     end
  end
end
-----------------------------------------------------------
local function posonmarker(xpos)
local num_markers=#jjstructure
local rep=-1
  for i = 1, num_markers do
    if xpos==jjstructure[i] then
      rep=i 
      break
      end
  end
  return rep
end 
--------------------------------------------------------------
local function faitstructencourssuiv(current_position)
  local structmax=#jjstructure
     if structmax==0 then return end
    if etatboucle==-1 then structmax=structfinboucle end
   if current_position< jjstructure[structmax] then
 if structureencours<structmax-1 then structureencours=structureencours+1 end
 end
end
-------------------------------------------------------------------------------
local function faitstrcencoursprec(current_position)
  if #jjstructure==0 then return end
 local n,d,tmpo=r.TimeMap_GetTimeSigAtTime(0,jjstructure[structureencours]+0.1)
 local structmin=1
 if etatboucle==-1 then structmin=structdebboucle end
 if current_position< jjstructure[structureencours]+tmpo/60 then
    if structureencours>structmin then structureencours=structureencours-1 end
  end
end
---------------------------------
local function  observeboucle()
-- flagboucle=    0 pas   1 tout le morceau  -1 valide mais partielle -2 pas valide
--local flagloop= r.GetSetRepeatEx(0, -1)
 if  r.GetSetRepeatEx(0, -1)==0  then  etatboucle= 0   
  else 
    local start,fin=r.GetSet_LoopTimeRange(false, true, 0, 0, false)
    if start==0 and fin==0 then etatboucle= 0  
    else
          structdebboucle=posonmarker(start)
          structfinboucle=posonmarker(fin)
          if structdebboucle==-1 or  structfinboucle==-1 then etatboucle=-2
          elseif structdebboucle==1 and structfinboucle==#jjstructure then etatboucle=1  -- la boucle est le morceau entier
          else etatboucle=-1 
          end
    end 
 end
 oldetatboucle=etatboucle
end
-------------------------------------
--------------------------------------------
local function settimeselleft()
local start, fin = r.GetSet_LoopTimeRange2(0,false, true, start, fin, true)

if fin==0 then fin=jjstructure[structureencours+1] end
start=jjstructure[structureencours]
--
r.GetSet_LoopTimeRange2(0,true, true, start, fin, true)
observeboucle()

end 
---------------------------------------
local function settimeselright()
local start, fin = r.GetSet_LoopTimeRange2(0,false, true, start, fin, true)

fin=jjstructure[structureencours+1]
if start==0 then start=jjstructure[structureencours]  end
r.GetSet_LoopTimeRange2(0,true, true, start, fin, true)
observeboucle()
end 
-----------------------------------
local function settimeselwhole()
local start, fin = r.GetSet_LoopTimeRange2(0,false, true, start, fin, true)
local start=jjstructure[1]
local fin=jjstructure[#jjstructure]
r.GetSet_LoopTimeRange2(0,true, true, start, fin, true)
observeboucle()
end 
---------------------------------------------------------------------------------
local function delmarkers()
local start, fin = r.GetSet_LoopTimeRange2(0,false, true, start, fin, true)
r.GetSet_LoopTimeRange2(0,true, true, 0, jjstructure[#jjstructure]+0.1, true)
 reaper.Main_OnCommand( 40420,0) --remove all markers in time sel
 r.GetSet_LoopTimeRange2(0,true, true, start, fin, true)
end 
-------------------------------------------
function  creertrackjjjjstarter(visible)
if not flagexistelivin then return end

local nbtracks=reaper.CountTracks(0)
        reaper.InsertTrackAtIndex(nbtracks, true)
   local startertrack = reaper.GetTrack(0,nbtracks)
        r.GetSetMediaTrackInfo_String(startertrack, 'P_NAME', "JJStarter", true)
 
      r.SetMediaTrackInfo_Value(startertrack, 'B_SHOWINMIXER', visible)
       r.SetMediaTrackInfo_Value(startertrack, 'B_SHOWINTCP', visible)
       
         r.SetMediaTrackInfo_Value(startertrack, 'C_BEATATTACHMODE', 1)
          r.SetMediaTrackInfo_Value(startertrack, 'I_RECINPUT',-1)
           r.SetMediaTrackInfo_Value(startertrack, 'I_RECMODE',2)
           r.SetMediaTrackInfo_Value(startertrack, 'I_RECMON',1)
            r.SetMediaTrackInfo_Value(startertrack, 'B_MAINSEND',0)
            r.SetMediaTrackInfo_Value(startertrack, 'D_VOL',0)
       
             r.SetMediaTrackInfo_Value(startertrack, 'I_MIDIHWOUT',curmidioutJJcomsid<<5)
--r.TrackFX_GetByName(startertrack, 'J2JJlatencySpy.jsfx',true) seult pour estimation
local qnfin=10
if #jjstructure>0 then qnfin=r.TimeMap2_timeToQN(0,jjstructure[#jjstructure]+4) --on deborde de 4 secondes pour éviter que Reaper ne s'arrête trop sec
end
  r.CreateNewMIDIItemInProj(startertrack, 0, qnfin, true)
  
end

----------------------------------------
local function cherchetrackjjstarter()
local xnotrackjjstarter=-1 
  local  count_all_tracks = reaper.CountTracks( 0 )
  for i = 0, count_all_tracks - 1 do
      local track = reaper.GetTrack(0, i)
      local rr, track_name = reaper.GetTrackName( track )
     if  string.find(track_name,"JJStarter")  then
      xnotrackjjstarter=i 
     return xnotrackjjstarter
      end
  end
  return xnotrackjjstarter
end
----------------------------------
local function gerertrackstarter()

local xtrindex= cherchetrackjjstarter()
if xtrindex~=-1 then 
  local track = reaper.GetTrack(0, xtrindex)
 r.DeleteTrack(track)
end
if not flagJJlabisoff then creertrackjjjjstarter(0) end
numtrackjjstarter= cherchetrackjjstarter()
end
------------------------------------------
local function traitejjlaboff()
   local newflagJJlabisoff= flagforceJJlaboff or not flagexistelivin
   if newflagJJlabisoff~=flagJJlabisoff then
      flagJJlabisoff=newflagJJlabisoff
      gerertrackstarter()  
    end

end
----------------------------------------------------------------
 local function etablitinputstatus()
   traitejjlaboff()
 if flagJJlabisoff then  
 latenceval=0
 flagusecompens=false
  inputname="JJazzJab OFF"
 elseif lastinputsrc==1 then
   flagusecompens=true
   latenceval=audiolatence
   inputname="FluidSynth"
 --  inpid=genjjaudioinputid
 elseif  lastinputsrc==2 then
  flagusecompens=true
   latenceval=midilatence
   inputname="JJazzMIDI"
 --  inpid=genjjmidiinputid
 elseif lastinputsrc==-1 then
  latenceval=0
  flagusecompens=false
   inputname="waiting"
  end
  
end
------------------------------------------------
local function getinfosviajjintracks()

 jjMIDIINid=-1
 numtrackjjmidi=-1
 numtrackjjaudio=-1

 local  count_all_tracks = reaper.CountTracks( 0 )
 for i = 0, count_all_tracks - 1 do
    local track = reaper.GetTrack(0, i)
    local rr, track_name = reaper.GetTrackName( track )
    if  string.find(track_name,codagejjazzinp)  then
      local rep= r.GetMediaTrackInfo_Value(track,'I_RECINPUT')
      if rep>=4096 then  --piste MIDI in 
          if jjMIDIINid==-1 then
          genjjmidiinputid=rep
            jjMIDIINid=(rep>>5)&0x3f
            numtrackjjmidi=i
        --    jjmidiinarmed=( r.GetMediaTrackInfo_Value(track,'I_RECARM')==1)
          end
      elseif rep>0 then --piste audio IN
        genjjaudioinputid=rep
         numtrackjjaudio=i
       --  jjaudioinarmed=( r.GetMediaTrackInfo_Value(track,'I_RECARM')==1)
         
       end
    end
    if numtrackjjmidi~=-1 and numtrackjjaudio~=-1 then break end
  end

   flagexistelivin= numtrackjjmidi~=-1 or numtrackjjaudio~=-1
   traitejjlaboff()

 numtrackjjstarter= cherchetrackjjstarter()
 
end
---------------------------------------------
local function  ashowmesures(xmesure)
--local TEXT_BASE_WIDTH  = ImGui.CalcTextSize(ctx, 'A')
--local TEXT_BASE_HEIGHT = ImGui.GetTextLineHeightWithSpacing(ctx)
local nbmesures=dureescum[#jjstructure]
local zone=math.floor((xmesure-1+decalagview)/nbmesparligne) 

local mesbase=nbmesparligne*zone+1-decalagview
local indexmesactu=(xmesure-1+decalagview)%nbmesparligne
local coulaff
 if kbactif then   coulaff=viewbgcolor else coulaff=viewbgcolor2 end   
 
 local flags = ImGui.TableFlags_Borders | ImGui.TableFlags_RowBg
if ImGui.BeginTable(ctx, '4mesurestable', nbmesparligne,flags) then
  ImGui.PushStyleColor(ctx, ImGui.Col_FrameBg, 0)
 ImGui.TableNextRow(ctx)
  ImGui.PushFont(ctx,font1)
 for i=0,nbmesparligne-1 do
 ImGui.TableNextColumn(ctx)
  if i==indexmesactu then   ImGui.TableSetBgColor(ctx, ImGui.TableBgTarget_CellBg, coulaff) end
 if (mesbase+i)>-3 then r.ImGui_Text(ctx, tostring(mesbase+i))
 else r.ImGui_Text(ctx,' ')
 end
  end
   ImGui.TableNextRow(ctx)
  
         ImGui.PopFont(ctx)
      
     ImGui.PushFont(ctx,fontes[taillacc] )  
for i=0,nbmesparligne-1 do
 ImGui.TableNextColumn(ctx)
  if mesbase+i<=nbmesures then
    if i==indexmesactu then   ImGui.TableSetBgColor(ctx, ImGui.TableBgTarget_CellBg, coulaff) end
    r.ImGui_Text(ctx, strmesure[mesbase+i])
 else
    r.ImGui_Text(ctx,' ')
    break
  end
end

    ImGui.EndTable(ctx)
     ImGui.PopFont(ctx)
  end
-----------------------------------------------futur
 local taillautres=math.max(taillacc-2,1)
 if nbfutur>0 then
 
    if ImGui.BeginTable(ctx, 'mesuressuiv', nbmesparligne,flags) then
       ImGui.PushFont(ctx,  fontes[taillautres])  
     ImGui.TableNextRow(ctx)
     if mesbase+nbmesparligne>nbmesures then
          ImGui.TableNextColumn(ctx)
        r.ImGui_Text(ctx, '  ')
        if nbfutur>1 then
         ImGui.TableNextRow(ctx)
         ImGui.TableNextColumn(ctx)
          r.ImGui_Text(ctx, '  ')
          end
     else
     
      for i=0,nbfutur*nbmesparligne-1 do
         ImGui.TableNextColumn(ctx)
         
        if mesbase+nbmesparligne+i<=nbmesures then
        
       if i==nbmesparligne then  ImGui.TableNextRow(ctx)  ImGui.TableNextColumn(ctx) end
      
       r.ImGui_Text(ctx, strmesure[mesbase+nbmesparligne+i])
      
         else
          r.ImGui_Text(ctx, '  ')
         ImGui.TableNextColumn(ctx)
           r.ImGui_Text(ctx, '  ')
          break
        end
      end
  end
   ImGui.PopFont(ctx)
  
  ImGui.EndTable(ctx)
end
end
  ImGui.PopStyleColor(ctx)
end
------------------------------
function Getdynpos()   
  local _playpos
  if reaper.GetPlayState()&1 == 1 then _playpos=reaper.GetPlayPosition()  
  else _playpos=reaper.GetCursorPosition()
  end
  return _playpos
  end
-------------------------------------------
local function faitlistemidiout()
midioutitems='None\0'
midioutnameslist={}
midioutidlist={}
 for i = 0,reaper.GetNumMIDIOutputs() do
  local retval, nameout = reaper.GetMIDIOutputName( i, '' )
  if retval==true then
    midioutnameslist[#midioutnameslist+1]=nameout
    midioutidlist[#midioutidlist+1]=i
    midioutitems=midioutitems.. i..' '..nameout..'\0'
    if curmidioutJJcomsid==i then curmidioutJJcomsidlindex=#midioutidlist   end
   end
 end
end
--------------------------
local function faitlistemidiin()
midiinitems='None\0'
midiinnameslist={}
midiinidlist={}
 for i = 0,reaper.GetNumMIDIInputs() do
    local retval, namein = reaper.GetMIDIInputName( i, '' )
    if retval==true then
       midiinnameslist[#midiinnameslist+1]=namein
       midiinidlist[#midiinidlist+1]=i
       midiinitems=midiinitems.. i..' '..namein..'\0'
       if jjaudiotapinid==i then jjaudiotapinidlindex=#midiinidlist end
      if curmidinlinkcomid==i then curmidinlinkcomidlindex=#midiinidlist end
   end
 end
end
-------------------------------------------
---------------------------
local function recalplay()
local curspos= reaper.GetCursorPosition()
reaper.SetEditCurPos(curspos-latenceval ,false,true) 
end
------------------------------
-----------------------------------
local function debreactivejj()
if flagJJlabisoff then return end
 muteunmuteinJJ(1)
 sendjjcommand('stop')
 if etatboucle==-1  then  sendjjcommand('play selection')
 else  sendjjcommand('play pause') end
flagreactivjjencours=true
  datetimeout=reaper.time_precise()+dureetimeout 

--log('debreactivs')
end
---------------------------------------
local function calejjazz(nostruct)
if flagJJlabisoff then return end
  if flagjjestsurstop then 
      debreactivejj()
      structacaler=nostruct
      return 
  end
  structacaler=-1
   sendjjcommand('gotostart') 
  if #jjstructure==0 or nostruct==0 then return end
   if etatboucle==-1 then nostruct=nostruct-structdebboucle+1 end
  if nostruct>1 then
      for i=1, nostruct-1 do
       sendjjcommand('suiv') 
      end
  end
end
---------------------------------
local function   mutestarter()
if numtrackjjstarter>0 then
local track = r.GetTrack(0,numtrackjjstarter)
 r.SetMediaTrackInfo_Value(track, 'B_MUTE',1)
 end
end
--------------------------------
--------------------------------------------

local function apreparedepart(xnote)
if flagJJlabisoff then return 0 end
 if etatboucle==-1 then
if structureencours<structdebboucle then structureencours=structdebboucle end
if structureencours>structfinboucle then structureencours=structfinboucle end
end
 calejjazz(structureencours) 
     if structacaler~=-1 then return -1 end

local track = r.GetTrack(0,numtrackjjstarter)
r.SetMediaTrackInfo_Value(track, 'B_MUTE',0)
item=r.GetTrackMediaItem(track, 0) 
local take = r.GetActiveTake(item)
-----nettoyage
local nbevts,nbnotes=r.MIDI_CountEvts(take)
if nbevts>0 then
 for i = nbevts-1,0,-1  do r.MIDI_DeleteEvt(take, i) end
end
---------------------
local posnote=jjstructure[structureencours]-latenceval
 local pqpos=  r.MIDI_GetPPQPosFromProjTime(take, posnote)
 r.MIDI_InsertNote(take,false, false, pqpos,pqpos+50, 0, xnote, 100)  --note déclancheuse
local posdepartjeu=posnote-latenceval-0.1 --un peu avant la note
  r.SetEditCurPos(posdepartjeu,true,true) 
 return posnote 
end
--------------------------------------------
-------------------------------------------------------
local function  boutonplaypause()
  
  if  not flagdynposdansmorceau then    reaper.OnPauseButton() return     end

  local playstate=reaper.GetPlayState()
  if  playstate&1==1 and posnotestart==-1 then 
     sendjjcommand('play pause')    
     reaper.OnPauseButton()
     return
  else
  if flagreactivjjencours then return end
  posnotestart= apreparedepart(24)
if  posnotestart==-1 then return end 
   end

 reaper.OnPlayButton() 
 flagjjestsurstop=false
end
--------------------------------------------
local function  boutonstop()
     reaper.OnStopButton()
      
       if  etatboucle==-1  
       then structureencours=structdebboucle
       else  structureencours=1
       end
     
     sendjjcommand('stop') 
       flagjjestsurstop=true 
       calejjazz(structureencours)
  reaper.SetEditCurPos(jjstructure[structureencours],true,true)   
  
end
--------------------------
local function boutonrecord()
local note=24
-- if etatboucle==-1 then note=32 end
 local playstate=reaper.GetPlayState()
if  playstate&1==1 then  reaper.Main_OnCommandEx( 1013, 1, 1) return 
else  
   posnotestart= apreparedepart(note)
  if  posnotestart==-1 then return end 
end
 
 reaper.Main_OnCommandEx( 1013, 1, 1)  --record&

    flagjjestsurstop=false
end
---------------------------
local function   boutongotostart()
  local onrepart= reaper.GetPlayState()==1
 boutonstop()
if  onrepart then boutonplaypause() end
 end      
-------------------------
local function boutonstrucprec()

  faitstrcencoursprec(precdynposition)
  reaper.SetEditCurPos(jjstructure[structureencours],true,true) 
  if  reaper.GetPlayState()==1 then
       if flagusecompens then recalplay()  end
        sendjjcommand('prec') 
   else calejjazz(structureencours)
  end
end
------------------------------
local function  boutonstructsuiv()

  faitstructencourssuiv(precdynposition)
  reaper.SetEditCurPos(jjstructure[structureencours],true,true)
  if  reaper.GetPlayState()==1 then
    if flagusecompens then recalplay() end
     sendjjcommand('suiv') 
  else calejjazz(structureencours)
  end
end
-------------------------------------
local function declenchebout(com)
  if #jjstructure==0 or structacaler>0 then return end
 if not flagforceJJlaboff then  getinfosviajjintracks() end

  if com==1 then boutonplaypause()
    elseif com==2 then boutonstop()
    elseif com==3 then boutonrecord()
    elseif com==4 then boutongotostart()
    elseif com==5 then boutonstrucprec()
    elseif com==6 then boutonstructsuiv()
  end
end
-------------------------------------------------
local function shortdejaemploye(xkey)
local rep=0
 if xkey>0 then
    for i=1, #mesboutons do
    if xkey==mesboutons[i].shortc then rep=i end
    end
  end
  return rep
end
------------------------------------------
local function shortmididejaemploye(ch,ty,val)
local rep=0
 if ch>0 then
    for i=1, #mesboutons do
    if mesboutons[i].cha ==ch and mesboutons[i].typ ==ty and mesboutons[i].val1 ==val then rep=i end
    end
  end
  return rep
end
------------------------------
local function resetstats()
 reaper.gmem_write(10,1)
      latencein=0
      nbessais=0
      valmoy=0
      sigma=0
    end
----------------------------
local function branchPCkeyb()
local text={}
 text[1]='2) Pilotage via raccourcis clavier du PC'  text[2]='2) Navigation via PC Keyboard Shortcuts'


 if ImGui.TreeNode(ctx, ('%s ###PCkeyCommands'):format(text[nolangue]) ) then
   ImGui.SameLine(ctx,0,40)
   HelpMarker(helpmess['KBshortc'][nolangue])
 
  rv,flagenableshorts=ImGui.Checkbox(ctx, 'Enable Shortcuts', flagenableshorts)
  if rv then
   reaper.SetExtState('J2jjazzlink', 'flagenableshorts',  tostring(flagenableshorts),true) 
     end
  ImGui.SameLine(ctx,0,20)    
   rv,flagsintercepteshorts=ImGui.Checkbox(ctx, 'Intercept Reaper Shorts', flagsintercepteshorts)
  if rv then
   reaper.SetExtState('J2jjazzlink', 'flagsintercepteshorts',  tostring(flagsintercepteshorts),true) 
     end
    if  inputshortboutselect>0 then
     reaper.ImGui_TextColored(ctx,0xFF00FFFF, 'Selected button : ') 
       ImGui.SameLine(ctx)
          rv,flaglearnkb=ImGui.Checkbox(ctx, 'Learnkb', flaglearnkb)
             ImGui.SameLine(ctx,0,10)
             if reaper.ImGui_SmallButton(ctx,'Delete') then    mesboutons[inputshortboutselect].shortc=-1 end
             if  flaglearnkb then
               for key, name in EachEnum('Key') do   
                 if key~=656 and key~=657 and key~=662 then
                    if ImGui.IsKeyDown(ctx, key) then 
                      if key==522 then  key=-1 end
                      if shortdejaemploye(key)>0 then inputshortboutselect= shortdejaemploye(key) end
                      mesboutons[inputshortboutselect].shortc=key
                     flaglearnkb=false
                       reaper.SetExtState('J2jjazzlink', 'boutonshortcut'..tostring(inputshortboutselect), tostring(key),true) 
                     end
                   end
                 end
               end 
        else
        reaper.ImGui_TextColored(ctx,0xFF00FFFF, 'Click on a button to edit shortc') 
        end
  
                          ---------------
 for nobout=1,#mesboutons do
    ImGui.PushStyleColor(ctx, ImGui.Col_Button,mesboutons[nobout].couleur)
    ImGui.PushID(ctx, nobout)
    
  if  reaper.ImGui_SmallButton(ctx,('%s ##nobout'):format( mesboutons[nobout].nom)) then 
    if  inputshortboutselect==nobout then
       inputshortboutselect=0
    else
       inputshortboutselect=nobout
    end 
  end
    ImGui.PopStyleColor(ctx)
    ImGui.PopID(ctx) 
      
    local trouve=false
    local namaff='-----'
      for key, name in EachEnum('Key') do
        if key==mesboutons[nobout].shortc then namaff=name
          trouve=true
        end
       if trouve then  break end 
      end 
      ImGui.SameLine(ctx)
      if nobout==inputshortboutselect then
       ImGui.TextColored(ctx, 0xFF00FFFF, namaff)
      else
       ImGui.Text(ctx, namaff)
      end
   end
 ImGui.TreePop(ctx) 
 end
end
-------------------------------------------------------------
local function branchejjcommands()
local text={}
 text[1]='1) Commandes midi envoyées à  JJazzLab'  text[2]='1) Midi commands sent to JJazzLab' 
 
  if ImGui.TreeNode(ctx, ('%s ###JJMIDIComs'):format(text[nolangue]) ) then
  ImGui.SameLine(ctx,0,40) 
 HelpMarker(helpmess['JJMidicmds'][nolangue])
 
   ImGui.SetNextItemWidth(ctx, ImGui.GetFontSize(ctx) * 12)  
   local rv,newitem = ImGui.Combo(ctx, 'Reaper Out to JJAZZ In', curmidioutJJcomsidlindex, midioutitems)
   if newitem~=curmidioutJJcomsidlindex then
      curmidioutJJcomsidlindex=newitem
      if curmidioutJJcomsidlindex>0 then curmidioutJJcomsid=midioutidlist[curmidioutJJcomsidlindex]  else curmidioutJJcomsid=-1 end
       r.SetExtState('J2jjazzlink', "curmidioutJJcomsid",tostring(curmidioutJJcomsid),true) 
    end
  
  if ImGui.BeginTable(ctx, 'jjcmdstable', 4) then
   for i,value in pairs(tabjjcom) do
       ImGui.TableNextRow(ctx)
        ImGui.TableNextColumn(ctx)
        reaper.ImGui_Text(ctx,tabjjcom[i].nom)
        ImGui.TableNextColumn(ctx)
        ImGui.PushID(ctx, i)
       local  rv,newnote =  ImGui.InputInt(ctx, '', tabjjcom[i].note)
       if rv then 
         tabjjcom[i].note=math.max(0,math.min(newnote,127))
         r.SetExtState('J2jjazzlink',tabjjcom[i].nom,tostring(tabjjcom[i].note),true) 
       end
       ImGui.PopID(ctx)
        ImGui.TableNextColumn(ctx)
        ImGui.Text(ctx,GetNoteName( tabjjcom[i].note))
    end
       ImGui.EndTable(ctx)
  end
 if  reaper.ImGui_SmallButton(ctx,'Restore JJazzLab defs') then 
    restorejjcomms()
 end
   reaper.gmem_write(11, tabjjcom['play pause'].note) 
  ImGui.SameLine(ctx,0,30)  reaper.ImGui_Text(ctx,'Test :')   ImGui.SameLine(ctx)
 if  reaper.ImGui_SmallButton(ctx,'Play/Pause') then 
     local memflag=flagJJlabisoff    --contournement assez vilain
     flagJJlabisoff=false
     sendjjcommand('play pause')
     flagJJlabisoff=memflag   
 end
 ImGui.TreePop(ctx) 
 end
end
-----------------------------------------------------
local function branchemidicmds()
local text={}
 text[1]='3) Pilotage via MIDI'  text[2]='3) Navigation via Midi'  
 
 
 if ImGui.TreeNode(ctx, ('%s ###MIDICommands'):format(text[nolangue]) ) then
 
 ImGui.SameLine(ctx,0,40)   
 HelpMarker(helpmess['Midicmds'][nolangue])
   ImGui.Spacing( ctx)   ImGui.Spacing( ctx) 
  rv,flagenablemidicmds=ImGui.Checkbox(ctx, 'Enable Midi commands', flagenablemidicmds)
  if rv then r.SetExtState('J2jjazzlink', 'flagenablemidicmds',  tostring(flagenablemidicmds),true)  end
    
   ImGui.SetNextItemWidth(ctx, ImGui.GetFontSize(ctx) * 14) 
 local rv,newitem = ImGui.Combo(ctx, 'Midi In for commands', curmidinlinkcomidlindex, midiinitems)
   if newitem~=curmidinlinkcomidlindex then
    curmidinlinkcomidlindex=newitem
    curmidinlinkcomid=midiinidlist[curmidinlinkcomidlindex]
    r.SetExtState('J2jjazzlink', "curmidinlinkcomid",tostring(curmidinlinkcomid),true) 
  end
  
  ImGui.AlignTextToFramePadding(ctx) 
  ImGui.Text(ctx,' ')
  ImGui.SameLine(ctx,0,40)
  ImGui.Text(ctx,'(0=Any) ')
  ImGui.SameLine(ctx,0,5)
  ImGui.SetNextItemWidth(ctx, ImGui.GetFontSize(ctx) * 6) 
 local rv,newfiltermidichan = ImGui.InputInt(ctx, 'Input channel', filtermidichan)
 if rv then 
   filtermidichan=math.min(16,math.max(0,newfiltermidichan))
    r.SetExtState('J2jjazzlink', "filtermidichan",tostring(filtermidichan),true) 
 end
     
                           ---------------
     ImGui.Spacing( ctx)   ImGui.Spacing( ctx)   
  if  inputshortboutbisselect>0 then
   reaper.ImGui_TextColored(ctx,0xFF00FFFF, 'Selected button : ') 
     ImGui.SameLine(ctx)
        rv,flaglearnmidi=ImGui.Checkbox(ctx, 'Learn', flaglearnmidi)
     
     if  flaglearnmidi then
          local ch,ty,val=GetMIDIInputbufs()
          if ch>0 then
            local dejala=shortmididejaemploye(ch,ty,val)
             if dejala>0 then inputshortboutbisselect= dejala end  
              mesboutons[inputshortboutbisselect].cha=ch  
              mesboutons[inputshortboutbisselect].typ=ty
              mesboutons[inputshortboutbisselect].val1=val 
              r.SetExtState('J2jjazzlink', "boutonsmidityp"..tostring(inputshortboutbisselect),tostring(ty),true)
              r.SetExtState('J2jjazzlink', "boutonsmidicha"..tostring(inputshortboutbisselect),tostring(ch),true)
              r.SetExtState('J2jjazzlink', "boutonsmidival1"..tostring(inputshortboutbisselect),tostring(val),true)
              local vidos= checkinputformidicmds() --pour vider l'entrée commandes
              flaglearnmidi=false
          end
       end 
      ImGui.SameLine(ctx,0,10)
      if reaper.ImGui_SmallButton(ctx,'Delete') then  
        mesboutons[inputshortboutbisselect].cha=-1 
        r.SetExtState('J2jjazzlink', "boutonsmidicha"..tostring(inputshortboutbisselect),tostring(-1),true)
      end
   else
     reaper.ImGui_TextColored(ctx,couleurselect, 'Click on a button to edit command') 
   end
                               --------------
 if ImGui.BeginTable(ctx, 'midicmdstable', 5) then

   for noboutbis=1,#mesboutons do
    ImGui.TableNextRow(ctx)
    ImGui.TableNextColumn(ctx)
      ImGui.PushStyleColor(ctx, ImGui.Col_Button,mesboutons[noboutbis].couleur)
      ImGui.PushID(ctx, noboutbis)
    if  reaper.ImGui_SmallButton(ctx,('%s ##noboutbis'):format( mesboutons[noboutbis].nom)) then 
      if  inputshortboutbisselect==noboutbis then
         inputshortboutbisselect=0
      else
         inputshortboutbisselect=noboutbis
      end 
    end
     ImGui.PopStyleColor(ctx)
      ImGui.PopID(ctx)
      if inputshortboutbisselect==noboutbis then  ImGui.PushStyleColor(ctx, ImGui.Col_Text,0xFF00FFFF) end
      local actif= (mesboutons[noboutbis].cha>0 )
      local pretext='-----'
     if actif then pretext= ('Cha %d'):format( mesboutons[noboutbis].cha) end
        ImGui.TableNextColumn(ctx)
        ImGui.Text(ctx,pretext)
        ImGui.TableNextColumn(ctx)
     if actif then ImGui.Text(ctx, MsgTypes[mesboutons[noboutbis].typ]) end
      ImGui.TableNextColumn(ctx)
     
     if mesboutons[noboutbis].typ==9 then pretext=GetNoteName(mesboutons[noboutbis].val1) else pretext=tostring(mesboutons[noboutbis].val1) end
     if actif then ImGui.Text(ctx,pretext)  end
     if inputshortboutbisselect==noboutbis then  ImGui.PopStyleColor(ctx)  end
    end
   ImGui.EndTable(ctx)
  end
 ImGui.TreePop(ctx) 
 end
end
-------------------------------------
local function brancheJJsignal()
local text={}
 text[2]='4) JJazzLab signal to Reaper'    text[1]='4) Signal de JJazzLab vers Reaper'
if ImGui.TreeNode(ctx, ('%s ###antibruits'):format(text[nolangue]) ) then
 
 ImGui.SameLine(ctx,0,40)   
  HelpMarker(helpmess['jjazzin'][nolangue])  
  
 text[2]=[[If needed, modify the letters sequence and see 
 witch track is recognized]]
 
 text[1]=[[Modifiez si besoin la séquence de lettres et vérifiez si 
 la ou les pistes sont bien reconnues]]
    r.ImGui_Text(ctx,text[nolangue])

  ImGui.SetNextItemWidth(ctx, ImGui.GetFontSize(ctx) * 6)
  local   rv,newcodagejjazzinp = ImGui.InputText(ctx,'Sequence',codagejjazzinp) 
     if newcodagejjazzinp~=codagejjazzinp then
        codagejjazzinp=newcodagejjazzinp
        r.SetProjExtState(0,'jjazzlinko', "codagejjazzinp",codagejjazzinp)
        getinfosviajjintracks()
     end
  ImGui.SameLine(ctx,0,15) 
     rv,flagforceJJlaboff=ImGui.Checkbox(ctx, 'Force JJazzLab OFF', flagforceJJlaboff)
     if rv then 
      r.SetProjExtState(0,'jjazzlinko', "flagforceJJlaboff",tostring(flagforceJJlaboff),true)
      
     end
    ImGui.SameLine(ctx) 
        HelpMarker(helpmess['jazzlabisoff'][nolangue]) 
     

reaper.ImGui_SeparatorText(ctx, "MIDI")

 if numtrackjjmidi==-1 then  r.ImGui_TextColored(ctx,couleurselect,'No MIDI JJazzIN track found')
 else
 local track=reaper.GetTrack(0,numtrackjjmidi)
 local rr, track_name = reaper.GetTrackName( track )
    r.ImGui_Text(ctx,'Track : ')  ImGui.SameLine(ctx)  r.ImGui_TextColored(ctx,couleurOK,tostring(1+numtrackjjmidi)..' '..track_name)
    ImGui.SameLine(ctx)
   if r.GetInputActivityLevel(genjjmidiinputid)>niveaubase then
    r.ImGui_TextColored(ctx,couleurOK,' Signal OK')
    else
      r.ImGui_TextColored(ctx,couleurselect,' No Signal')
    end
   if lastinputsrc==2 then ImGui.SameLine(ctx,0,20)  r.ImGui_TextColored(ctx,couleurOK,'Active') end
 end

reaper.ImGui_SeparatorText(ctx, "JJAZZ Fluidsynth Audio")
 if numtrackjjaudio==-1 then  r.ImGui_TextColored(ctx,couleurselect,'No Audio JJazzIN track found')
 else
     local track=reaper.GetTrack(0,numtrackjjaudio)
     local rr, track_name = reaper.GetTrackName( track )
       r.ImGui_Text(ctx,'Track : ')  ImGui.SameLine(ctx)  r.ImGui_TextColored(ctx,couleurOK,tostring(1+numtrackjjaudio)..' '..track_name)
     ImGui.SameLine(ctx)
     if r.GetInputActivityLevel(genjjaudioinputid)>niveaubase then
      r.ImGui_TextColored(ctx,couleurOK,' Signal OK')
      else
        r.ImGui_TextColored(ctx,couleurselect,' No Signal')
      end
     if lastinputsrc==1 then ImGui.SameLine(ctx,0,20)  r.ImGui_TextColored(ctx,couleurOK,'Active') end
  end  
 ImGui.TreePop(ctx) 
 end
end

------------------------------------------------
local function branchelatence()
if flagJJlabisoff then return end
local text={}
 text[2]='5) Latency compensation to sync starts'    text[1]='5) Compensation latence pour synchro départs'
  
  if ImGui.TreeNode(ctx, ('%s ###lat'):format(text[nolangue]) ) then
  if  lastinputsrc==- 1 then r.ImGui_Text(ctx,'Please send a signal from JJazzLab') end
 if  lastinputsrc==1 then 
 ---------------------------------------------------------------------audio
   ImGui.Spacing( ctx)   ImGui.Spacing( ctx) 
   ImGui.SetNextItemWidth(ctx, ImGui.GetFontSize(ctx) *8) 
      local rv,newaudiolatence = ImGui.InputDouble(ctx, 'for', audiolatence, 0.0001, 1, '%.4f s')
      if newaudiolatence~=audiolatence then
         audiolatence=newaudiolatence
         r.SetExtState('J2jjazzlink', "audiolatence",tostring(audiolatence),true) 
     end
    ImGui.SameLine(ctx)  r.ImGui_TextColored(ctx,couleurOK,inputname)
    ImGui.SameLine(ctx,0,5) 
         HelpMarker(helpmess['latencea'][nolangue])  
    
 end
   if  lastinputsrc==2 then   
    -------------------------------------------------------------MIDI
       ImGui.Spacing( ctx)   ImGui.Spacing( ctx) 
      ImGui.SetNextItemWidth(ctx, ImGui.GetFontSize(ctx) *8) 
     local rv,newmidilatence = ImGui.InputDouble(ctx, 'with', midilatence, 0.0001, 1, '%.4f s')
          if newmidilatence~=midilatence then
             midilatence=newmidilatence
             r.SetExtState('J2jjazzlink', "midilatence",tostring(midilatence),true) 
         end
    ImGui.SameLine(ctx)  r.ImGui_TextColored(ctx,couleurOK,inputname)
    ImGui.SameLine(ctx,0,5) 
         HelpMarker(helpmess['latencem'][nolangue])  
      
      if ImGui.SmallButton(ctx, 'SET') then
      vstidrumtrackname=cherchefirstslecttrackname()
        r.SetExtState('J2jjazzlink', "vstidrumtrackname",vstidrumtrackname,true)
       end  
         ImGui.SameLine(ctx) reaper.ImGui_Text(ctx,'Drum track')
          numdrumtrack=cherchenotrack(vstidrumtrackname)
      ImGui.SameLine(ctx)  r.ImGui_TextColored(ctx,couleurOK,tostring(1+numdrumtrack)..' '..vstidrumtrackname)
    
     
    if numdrumtrack==-1 then
     ImGui.SameLine(ctx)  r.ImGui_TextColored(ctx,couleurselect,'Not found')
      reaper.ImGui_Text(ctx,helpmess['vstidrum'][nolangue])
    end
       
  end
     -------------------------------------------Estimation 
      if  lastinputsrc==1 or  (lastinputsrc==2  and numdrumtrack~=-1) then   
         ImGui.Spacing( ctx)   ImGui.Spacing( ctx) 
   
  if ImGui.Button(ctx, 'Estimate latency') and  ayasignaldejjazz()==false then
   
    reaper.Main_OnCommand( 41746,0) --disable metronome
     local flagnosignal=false
  if   cherchetrackjjstarter()==-1 then creertrackjjjjstarter(0) end
  numtrackjjstarter=cherchetrackjjstarter()
  local starttrack = r.GetTrack(0,numtrackjjstarter)
 if r.TrackFX_GetByName(starttrack, 'J2JJlatencySpy.jsfx',false)==-1 then r.TrackFX_GetByName(starttrack, 'J2JJlatencySpy.jsfx',true) end 
  local sourcetrack
  if lastinputsrc==2 then  
   sourcetrack=r.GetTrack(0,numdrumtrack)
   elseif   lastinputsrc==1 then
     sourcetrack=r.GetTrack(0,numtrackjjaudio)
   end
if  r.GetTrackNumSends(starttrack, -1)> 0 then r.RemoveTrackSend(starttrack, -1,0) end
          r.CreateTrackSend(sourcetrack, starttrack)
          r.SetTrackSendInfo_Value(starttrack, -1,0,'I_MIDIFLAGS',31)
          r.SetTrackSendInfo_Value(starttrack, -1,0,'I_SENDMODE',3)
       
 r.SetMediaTrackInfo_Value(starttrack, 'B_MUTE',0)
   item=r.GetTrackMediaItem(starttrack, 0) 
  local take = r.GetActiveTake(item)
  -----nettoyage
  local nbevts,nbnotes=r.MIDI_CountEvts(take)
  if nbevts>0 then
   for i = nbevts-1,0  do r.MIDI_DeleteEvt(take, i) end
  end
  local posnote=r.TimeMap_GetMeasureInfo(0, 1)
   local pqpos=  r.MIDI_GetPPQPosFromProjTime(take, posnote)
   r.MIDI_InsertNote(take,false, false, pqpos,pqpos+50, 0,24, 100)  --note déclancheuse
  local posdepartjeu=posnote-0.1   --un peu avant la note
    r.SetEditCurPos(posdepartjeu,true,true)
   datestoprec=reaper.time_precise()+0.5 
  --  reaper.Main_OnCommandEx( 1013, 1, 1)
  reaper.OnPlayButton()
  end
  ImGui.SameLine(ctx)
    r.ImGui_Text(ctx,'latencein :') ImGui.SameLine(ctx)  r.ImGui_Text(ctx,string.format('%.04f',latencein))
  ImGui.SameLine(ctx)
    if ImGui.Button(ctx, 'Reset stats') then resetstats() end
     
 --------------
 local data = reaper.gmem_read(1) 
  if data > 0 then
   reaper.gmem_write(1,0)
  latencein=data
  nbessais=reaper.gmem_read(2)
  valmoy=reaper.gmem_read(3)
  sigma=reaper.gmem_read(4)
  end
 local texte={}
 texte[1]='moyenne :'   texte[2]='average :'  
    r.ImGui_Text(ctx,'nb essais :') ImGui.SameLine(ctx)  r.ImGui_Text(ctx,string.format('%d',nbessais))
    ImGui.SameLine(ctx)
     r.ImGui_Text(ctx,texte[nolangue]) ImGui.SameLine(ctx)  r.ImGui_Text(ctx,string.format('%.04f',valmoy))
     ImGui.SameLine(ctx)
      r.ImGui_Text(ctx,'sigma :') ImGui.SameLine(ctx)  r.ImGui_Text(ctx,string.format('%.06f',sigma))
end


   ImGui.TreePop(ctx) 
   end
  end
 
------------------------------------------------
local function bsetupcontent()

 local olddlang=nolangue
  ImGui.SetNextItemWidth(ctx, ImGui.GetFontSize(ctx) * 0.5)
  rv,nolangue = ImGui.RadioButtonEx(ctx, 'Français', nolangue, 1); ImGui.SameLine(ctx,0,40)
  rv,nolangue = ImGui.RadioButtonEx(ctx, 'English', nolangue, 2) --ImGui.SameLine(ctx,0,10)
   r.SetExtState('J2jjazzlink', "nolangue",tostring(nolangue),true) 
  local txt={}
  txt[1]='sera créée en chargeant un JJazz sng'  txt[2]='will be created when loading a JJazz sng' 
  rv,flagpistechords=ImGui.Checkbox(ctx, 'Chord track', flagpistechords)
  if rv then 
   r.SetExtState('J2jjazzlink', "flagpistechords",tostring(flagpistechords),true)  
  end
  ImGui.SameLine(ctx) reaper.ImGui_Text(ctx,txt[nolangue])

  branchejjcommands()   
  branchPCkeyb()   
  branchemidicmds()
  brancheJJsignal()
  branchelatence()
 
  etablitinputstatus()
end 
------------------------------------------------------------------------------------
local function bwindowpointagemorceau()

if not flagshowview then return end

local color=0xFFAAEEFF
  local viewport = ImGui.GetMainViewport(ctx)
  local base_pos_x, base_pos_y = ImGui.Viewport_GetPos(viewport)
  ImGui.SetNextWindowPos(ctx, base_pos_x + 100, base_pos_y + 100,ImGui.Cond_FirstUseEver)   --,WindowFlags_NoSavedSettings)    -- reaper.ImGui_Cond_Once()
 reaper.ImGui_SetNextWindowSize(ctx,vieww,viewh,WindowFlags_NoSavedSettings)
if  ImGui.Begin(ctx, ('J2JAZZView %s ###Pointage'):format(nommorceau),false,window_flags) then

local viewport2 = ImGui.GetWindowViewport(ctx)
local newvieww,newviewh=ImGui.Viewport_GetSize(viewport2)   
 if newvieww~=vieww or newviewh~=viewh then
     vieww=newvieww  viewh=newviewh 
  r.SetProjExtState(0,'jjazzlinko', "vieww",tostring(vieww),true)
   r.SetProjExtState(0,'jjazzlinko', "viewh",tostring(viewh),true)
    -- blog(vieww) log(viewh) 
  end
  if kbactif then   color=0x77CBD0FF end
-- ImGui.AlignTextToFramePadding(ctx) 
  ImGui.PushFont(ctx,  font4)  
  ImGui.TextColored(ctx, color, '#'..tostring(structureencours)..' ')
 
  
        ImGui.SameLine(ctx)
        local txt=nomsstruct[structureencours]
        if mesureencours<1 then txt='-----------'  end
        ImGui.SetNextItemWidth(ctx, ImGui.GetFontSize(ctx) * 10)
        if kbactif then    
       ImGui.Text(ctx,txt) 
      
      else   ImGui.TextDisabled(ctx,txt) end
        ImGui.PopFont(ctx)
         ImGui.PushFont(ctx,  font3) 
           -- ImGui.AlignTextToFramePadding(ctx)
       
        local longtot = ImGui.GetWindowWidth(ctx)
     ImGui.SameLine(ctx,longtot-250,0)
  
     
    ImGui.Text(ctx,'   mes : ')
     ImGui.SameLine(ctx,0,0)
     if flagdynposdansmorceau then
        local strnbmes=tostring(mesureencours-dureescum[structureencours])
        ImGui.TextColored(ctx,color,strnbmes)
        if  mesureencours>0 then
          ImGui.SameLine(ctx,0,0)
          ImGui.TextColored(ctx,color,'->'..tostring(durees[structureencours])..'     ')
        end
     end
 
    ImGui.SameLine(ctx,0,30)
    
   ImGui.TextColored(ctx, color,tostring(mesureencours))
   if flagdynposdansmorceau then
    ImGui.SameLine(ctx, 0, 5)
   ImGui.Text(ctx,'->'..tostring(dureescum[#jjstructure]))
   end
 
   ImGui.PopFont(ctx)
   ashowmesures(mesureencours)
     ImGui.PushFont(ctx,  font1) 
   local longtot = ImGui.GetWindowWidth(ctx)
      
       ImGui.SetNextItemWidth(ctx, ImGui.GetFontSize(ctx) *6) 
           local rv,newnbmesparligne = reaper.ImGui_InputInt(ctx, 'Mes/line', nbmesparligne, 1, 1,1)
                if newnbmesparligne~=nbmesparligne then
                   nbmesparligne=math.min(12,math.max(newnbmesparligne,2))
             r.SetProjExtState(0,'jjazzlinko', "nbmesparligne",tostring(nbmesparligne),true)
        
               end
        ImGui.SameLine(ctx,0,40)  
       ImGui.SetNextItemWidth(ctx, ImGui.GetFontSize(ctx) *6) 
           local rv,newdecalagview = reaper.ImGui_InputInt(ctx, 'Decal view', decalagview, 1, 1,1)
                if newdecalagview~=decalagview then
                   decalagview=math.min(5,math.max(newdecalagview,-5))
              
             r.SetProjExtState(0,'jjazzlinko', "decalagview",tostring(decalagview),true)
           end   
       
              
      ImGui.SameLine(ctx,0,40)  
            
            ImGui.SetNextItemWidth(ctx, ImGui.GetFontSize(ctx) *6) 
                local rv,newnbfutur = reaper.ImGui_InputInt(ctx, 'Nb futur', nbfutur, 1, 1,1)
                     if newnbfutur~=nbfutur then
                        nbfutur=math.min(2,math.max(newnbfutur,0))
                      --  nbfutur=newnbfutur
                  r.SetProjExtState(0,'jjazzlinko', "nbfutur",tostring(nbfutur),true)
                end 
       
       
           rv,flagnoprefix=ImGui.Checkbox(ctx, 'No lenght codage', flagnoprefix)
           if rv then 
            r.SetProjExtState(0,'jjazzlinko', "flagnoprefix",tostring(flagnoprefix),true)
            faitstrings4mesuresdaff()
           end
           
         ImGui.SameLine(ctx,0,15)
         ImGui.SetNextItemWidth(ctx, ImGui.GetFontSize(ctx) *6) 
             local rv,newtaillacc = reaper.ImGui_InputInt(ctx, 'Size', taillacc, 1, 1,1)
                  if newtaillacc~=taillacc then
                     taillacc=math.min(5,math.max(newtaillacc,1))
               r.SetProjExtState(0,'jjazzlinko', "taillacc",tostring(taillacc),true)
                end
      
         ImGui.PopFont(ctx) 
 
   ImGui.End(ctx)
  end
 end
---------------------------------------------------
local function  bruncontent()
 local rv
local xnobout
 ImGui.BeginDisabled(ctx, #jjstructure==0)
-------------------------LIGNE1-------------------------------------------------
 if flagsintercepteshorts then 
  ImGui.SetNextFrameWantCaptureKeyboard(ctx, true)
  else
   ImGui.SetNextFrameWantCaptureKeyboard(ctx, false)
   end
   
 xnobout=1
 local coul=mesboutons[xnobout].couleur
 ImGui.PushStyleColor(ctx, ImGui.Col_Button,coul)
 if flagenableshorts and  mesboutons[xnobout].shortc>0  then 
 ImGui.SetNextItemShortcut(ctx, mesboutons[xnobout].shortc,  ImGui.InputFlags_RouteGlobal)   end
  if  ImGui.Button(ctx, 'Play-Pause',boutsize,bouth) then  declenchebout(xnobout) end
   ImGui.PopStyleColor(ctx)
   ImGui.SameLine(ctx)
   

  xnobout=2 
   ImGui.PushStyleColor(ctx, ImGui.Col_Button,mesboutons[xnobout].couleur)
 if flagenableshorts and  mesboutons[xnobout].shortc>0  then 
 ImGui.SetNextItemShortcut(ctx, mesboutons[xnobout].shortc,  ImGui.InputFlags_RouteGlobal)   end
  if  ImGui.Button(ctx, 'Stop',boutsize,bouth) then   declenchebout(xnobout)    end 
     ImGui.PopStyleColor(ctx)
     
   xnobout=3
   ImGui.SameLine(ctx)
    ImGui.PushStyleColor(ctx, ImGui.Col_Button,mesboutons[xnobout].couleur)
 if flagenableshorts and  mesboutons[xnobout].shortc>0  then 
 ImGui.SetNextItemShortcut(ctx, mesboutons[xnobout].shortc,  ImGui.InputFlags_RouteGlobal)   end
  if ImGui.Button(ctx, 'RECORD',boutsize,bouth) then   declenchebout(xnobout)    end
     ImGui.PopStyleColor(ctx)
  --------------------------------------------LIGNE2---------------------------------------------------

  xnobout=4
   ImGui.PushStyleColor(ctx, ImGui.Col_Button,mesboutons[xnobout].couleur)
  if flagenableshorts and  mesboutons[xnobout].shortc>0  then 
  ImGui.SetNextItemShortcut(ctx, mesboutons[xnobout].shortc,  ImGui.InputFlags_RouteGlobal)   end
   if ImGui.Button(ctx, 'GotoStart',boutsize,bouth) then  declenchebout(xnobout)  end
   ImGui.PopStyleColor(ctx)
  
 ImGui.SameLine(ctx)
 
  xnobout=5
 ImGui.PushStyleColor(ctx, ImGui.Col_Button,mesboutons[xnobout].couleur)
 if flagenableshorts and  mesboutons[xnobout].shortc>0  then 
 ImGui.SetNextItemShortcut(ctx, mesboutons[xnobout].shortc,  ImGui.InputFlags_RouteGlobal)   end
  if ImGui.Button(ctx, 'Prev',boutsize,bouth) then declenchebout(xnobout)  end
  ImGui.PopStyleColor(ctx)
    
    xnobout=6
   ImGui.SameLine(ctx)  
   ImGui.PushStyleColor(ctx, ImGui.Col_Button,mesboutons[xnobout].couleur)
 if flagenableshorts and  mesboutons[xnobout].shortc>0  then 
 ImGui.SetNextItemShortcut(ctx, mesboutons[xnobout].shortc,  ImGui.InputFlags_RouteGlobal)   end
    if ImGui.Button(ctx, 'Next',boutsize,bouth) then  declenchebout(xnobout)   end
    ImGui.PopStyleColor(ctx)
ImGui.EndDisabled( ctx)
------------------------------------LIGNE 3------------------------------------
 local txt={}
  txt[1]='Placer le curseur entre les bornes d une region et cliquer'
   txt[2]='Place the cursor betwween the  boudaries of an element, and click'
  ImGui.AlignTextToFramePadding(ctx)
   if etatboucle==-2 and not flagJJlabisoff then
   reaper.ImGui_TextColored(ctx,couleurselect, 'Wrong Loop')
   else
  ImGui.Text(ctx, 'Set Loop ')
  end
   ImGui.SameLine(ctx)
  if ImGui.Button(ctx, 'Left ') then
  settimeselleft()
  end
     ImGui.SetItemTooltip(ctx, txt[nolangue]) 
  ImGui.SameLine(ctx,0,15)
   
  if ImGui.Button(ctx, 'Right') then
  settimeselright()
  end
      ImGui.SetItemTooltip(ctx, txt[nolangue]) 
   
    ImGui.SameLine(ctx,0,15)  
  if ImGui.Button(ctx, 'Whole song') then
   settimeselwhole()
  end
              
---------------------------------LIGNE4-------------------------

   if ImGui.Button(ctx,'Reaper Click Settings') then 
    reaper.Main_OnCommandEx( 40363, 1, 1)
   end
  ImGui.SameLine(ctx,0,25) 
 ImGui.PushStyleColor(ctx,ImGui.Col_Button,HSV(0.596,1,1,1))
 
 ImGui.SetNextItemWidth(ctx, ImGui.GetFontSize(ctx) * 8)  
  if ImGui.Button(ctx, 'Other JJazz.sng') then
  local rep=aimporterJJAZZsng()
 if rep==0 then   reaper.ShowMessageBox('Error, sng not loaded, JJazzLab version problem. Try to save it with JJazzLab 5.1 after a micro modification','sng NOT LOADED',0)
   elseif rep==1 then
  if #jjstructure>0 then 
     faitstrings4mesuresdaff()
       gerertrackstarter()
       r.SetEditCurPos(jjstructure[1],true,true) 
      structureencours=1 
      end
     end
 end
  ImGui.PopStyleColor(ctx)
       
   
--------------------------------LIGNE5-------------------------------------
     
 
    rv,flagshowview=ImGui.Checkbox(ctx, 'Viewer', flagshowview)
     if rv then  
      reaper.SetProjExtState(0, 'jjazzlinko', 'flagshowview',  tostring(flagshowview))
        end
   -------------------------------LIGNE6-------------------------------------
      ImGui.SameLine(ctx,0,15)     
       
      
 if ImGui.Button(ctx,'Setup') then 
    reaper.OnStopButton()
    sendjjcommand('stop')
    
    resetstats()
    flagdebsetup=true
    faitlistemidiout()
    faitlistemidiin()
    ImGui.OpenPopup(ctx, 'J2JAZZLinkSetup') 
    
    end 
   mainwcenter_x, mainwcenter_y = ImGui.Viewport_GetCenter(r.ImGui_GetMainViewport(ctx)) 
   ImGui.SetNextWindowPos(ctx, mainwcenter_x, mainwcenter_y-50, ImGui.Cond_Appearing, 0.5, 0.5)
  reaper.ImGui_SetNextWindowSize(ctx,330,360,ImGui_Cond_FirstUseEver)
   if ImGui.BeginPopupModal(ctx, 'J2JAZZLinkSetup', true) then
  
        bsetupcontent()
        ImGui.EndPopup(ctx)
     end
     
  ImGui.SameLine(ctx,0,15)  
  reaper.ImGui_TextColored(ctx,couleurOK, 'In : '..inputname)

 
--[[


 if ImGui.Button(ctx, 'infos') then

atrackinfoview()

 end
]]
----------------
end     --de runcontent()
-------------------------------------------------------------------
----------------------------------------------------------
local function cherchestructencours(pos)
local rep=1
local valid=true
local nbstruct=#jjstructure  
  if nbstruct>0 then 
    if pos >jjstructure[nbstruct] then  rep=nbstruct-1  valid=false
  else
        for i=1,#jjstructure-1 do
            if pos>=jjstructure[i] and pos<jjstructure[i+1] then
            rep=i
            end
        end 
    end
  end
  return valid,rep
end
-----------------------------------------
local function OnClose()

end
---------------------------------------------
------------------------------------
local function existedansruler()
 local nbtot=  r.GetNumRegionsOrMarkers(0)
 local rep=false
  if nbtot==0 then return rep end
   
     for j=0,nbtot-1 do
       local obj = r.GetRegionOrMarker(0, j, '') 
           local lane_idx= r.GetRegionOrMarkerInfo_Value(0, obj, 'I_LANENUMBER')
             local isregn= r.GetRegionOrMarkerInfo_Value(0, obj, 'B_ISREGION')
        -- local markrgnindexnumber= r.GetRegionOrMarkerInfo_Value(0, obj, 'I_INDEX')
         local rv,name= r.GetSetRegionOrMarkerInfo_String(0, obj,'P_NAME', '', false)
         
       if isregn and  string.sub(name,1,5) =='JJazz' and lane_idx==1 then rep=true break end
      end
     -- log(tostring(rep))
  return rep
end
----------------------------
--
local function verifstructure()
-- local nbtot,nbmark,nbregions=r.CountProjectMarkers(0)
 
  if  existedansruler() then 
       getjjstructure()
      numtrackjjstarter= cherchetrackjjstarter()
      
     else
    jjstructure={}
    nommorceau=''
    reaper.SetProjExtState(0, 'jjazzlinko', 'nommorceau', nommorceau)
    end

     getinfosviajjintracks()
  -- log('verifstruct')
   return #jjstructure>0
end
-----------------------------------------------
local function demarrage()
      chargeexstatescript()
      chargeprojectexstate()
  
      faitlistemidiout()
      faitlistemidiin()
        verifstructure()
      oldflagloop= r.GetSetRepeatEx(0, -1)
      oldboucleactive= r.GetSetRepeatEx(0, -1)
      observeboucle()
       getinfosviajjintracks()
       etablitinputstatus()
      
      end
------------------------------------
local function pollingreactivationjj()
-- but : remettre jjazzlab sur pause, après un debreactivejj(), en évitant d'entendre les sons
-- grâce à un démutage des pistes d'entrée jjazzlab une fois que jjazzlab a fini de préparer la musique
-- et finir en recalant jjazzlab sur la structure en cours
   local tactu=reaper.time_precise()
  if flagreactivjjencours then
    if  tactu>datetimeout   then 
    local text={}
    text[2]='Error, no signal from  JJazzLab. cf setup 4)'
    text[1]='Erreur, pas signal de JJazzLab. cf setup 4)'
      reaper.ShowMessageBox(text[nolangue],'No JJazzLab signal',0)
      flagreactivjjencours=false
        structacaler=-1
         sendjjcommand('stop')
      flagjjestsurstop=true
        muteunmuteinJJ(0)
    return
     end
      if  ayasignaldejjazz() and datefinattente==0  then
   --  log('poll1')
        sendjjcommand('play pause') 
        flagjjestsurstop=false
        datefinattente=tactu+dureeattente
      end
     if datefinattente>0 and tactu>datefinattente  then
       muteunmuteinJJ(0)
       flagreactivjjencours=false
        datefinattente=0
      end
  end
  
  if structacaler>0 and not flagreactivjjencours then
    calejjazz(structacaler)
    structacaler=-1
  end
  
 if datestoprec>0 and datestoprec<tactu then  ---pour estimation latence
  reaper.OnStopButton()
    muteunmuteinJJ(1)
  sendjjcommand('stop')

   sendjjcommand('play pause')
    sendjjcommand('play pause')
     sendjjcommand('gotostart') 
   
  reaper.Main_OnCommand( 41745,0) --enable metronome
  datestoprec=-1
  local posnote=r.TimeMap_GetMeasureInfo(0, 1)
  r.SetEditCurPos(posnote,true,true)
   datefinrecallatencytry=tactu+dureeattente
 end
 if datefinrecallatencytry>0 and datefinrecallatencytry<tactu then
   muteunmuteinJJ(0)
  datefinrecallatencytry=0
 end
end
--------------------------------------------------------------------------------------------
local function loop()

if premierpassage then 
  initvars()
  demarrage()   
  premierpassage=false   
end

pollingreactivationjj()

if lastinputsrc==-1 and flagexistelivin then 
  local rep,newsrc=ayasignaldejjazz() 
  if rep then lastinputsrc=newsrc  etablitinputstatus() end
 -- log('loop1') log(lastinputsrc)
end
if r.GetSetRepeatEx(0, -1)~=oldboucleactive then 

 sendjjcommand('loop')
 sendjjcommand('stop')
  flagjjestsurstop=true
  oldboucleactive= r.GetSetRepeatEx(0, -1)
  observeboucle()
end
local nouvetatproj=r.GetProjectStateChangeCount(0)
  local pstate=reaper.GetPlayState()
  ------------------------------0
if pstate&1~=1 then
-------------------------------------01
 if nouvetatproj~=etatprojet then
-- log('nouvetatproj')
    etatprojet=nouvetatproj
   if not flagforceJJlaboff then  getinfosviajjintracks() end
--   if  verifstructure() then  observeboucle()   end
---essai verif project : cas ou on ouvre un fichier sans fermer JJazzLink-------------- 
      local exists, actunommorceau = reaper.GetProjExtState(0, 'jjazzlinko',  'nommorceau')
 -- if exists ~= 0 then
      if nommorceau~=actunommorceau then 
   --  log('redém')
     
      premierpassage=true
   end
 end
-----01-------------------------------02--------------------  
  if flagexistelivin and not flagforceJJlaboff then
    local rep,newsrc=ayasignaldejjazz() 
    if rep and newsrc~=lastinputsrc then 
      lastinputsrc=newsrc 
      etablitinputstatus()
      resetstats()
    end
  end
--02---------------------------- 
end
----0--------------------1
if #jjstructure>1 and not premierpassge then

    local dynposition=Getdynpos()
  -----------------------11
    if  dynposition~=precdynposition then
         flagdynposdansmorceau, structureencours=cherchestructencours(dynposition)
         mesureencours=r.TimeMap_QNToMeasures(0,r.TimeMap2_timeToQN(0,dynposition))-3
      
        if pstate &1 ==1  then
          if   dynposition> jjstructure[#jjstructure]  then flagjjestsurstop=true 
          elseif posnotestart~=-1 and dynposition>posnotestart  then mutestarter()  posnotestart=-1
          end
        else
      if (etatboucle==0 or etatboucle==-1 )and flagdynposdansmorceau and not flagJJlabisoff then   calejjazz(structureencours)  end   -- log('deprecalage')
        end 
        precdynposition=dynposition   
     end
  ----11
 
--12--------------------------
     if flagenablemidicmds  then
        local com=checkinputformidicmds()
        if com>0 and flagenablemidicmds then   declenchebout(com) end
      end
      ---12-----------------
end
-----1
-- ImGui.SetNextWindowSize(ctx, 230,120, ImGui_Cond_None) --a élucider
--ImGui.SetNextWindowSize(ctx, 230,120, 0)


 local colorpushed=false 
  kbactif =ImGui.IsWindowFocused(ctx, ImGui.FocusedFlags_AnyWindow)
   if  kbactif  then
     reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_TitleBg(), 0x2D7CABFF)                   
     reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_TitleBgActive(), 0x2D7CABFF)
     colorpushed=true 
   end
--------------------- 
local visible, open= ImGui.Begin(ctx, ('J2JAZZLink %s ###JJAZZLink'):format(nommorceau),true,window_flags|ImGui.WindowFlags_NoCollapse)
 if visible then
    ImGui.PushFont(ctx, font)
    bruncontent()
    if #jjstructure>0 then  bwindowpointagemorceau() end
   
     ImGui.PopFont(ctx)
    if  colorpushed then  reaper.ImGui_PopStyleColor(ctx,2) colorpushed=false end
    ImGui.End(ctx)
  end
  
  if open then
    reaper.defer(loop)
    else
      OnClose()
    end
  end

reaper.defer(loop)

----------------------------------------------------

