/*
    New Frontier Chatter Script (by Tenaar Feiri aka Elerlissa Ashbourne)
    Installation:
        - Place script in any object you're using on your character.
        - Set up name with: /1 name Your Name
        - Use /1 help for further instructions as needed.        
*/
///////////////////
integer devMode = FALSE;
string helpStr = "Post \"/1 help\" without quotes in chat for instructions.";
string instructions = "Chatter instructions:
Emotes on channel 4:
    - /4 does a thing. (Emotes)
    - /4! does a thing. (Emotes but in shout.)
    - /4: Hello! (Quick chat, produces: Yourname says, \"Hello!\")
    - /4# Hello! (Quick chat, produces: Yourname whispers, \"Hello!\" in whisper (max range 10m))
    - /3 Stuff! (Emotes without your name)
    - /3# Stuff! (Same as above, but in whisper)
    - /3! Stuff! (Same as above but in shout)
    - /22 Some shit! (OOC post. Produces: Charname (Username) OOC: Some shit!)

Settings on channel 1:
    - /1 name (Set your name. Example: /1 name Iua Metjer-Efet)
        - Use $n to set custom limiter for togglename. Example: Iua Metjer$n-Efet (produces: \"Iua Metjer\" in chat)
    - /1 togglewhisper (Toggles between posting at 10m range or 20m range)
    - /1 togglename (Toggles whether to use the first or full name. Use $n in your name to define a custom limiter.)
";
string curName;
list allowedSpecials = ["-","'",".",",",":",";"];
integer specialName; 
integer togglename;
integer whisper;
integer postMode;
integer chan = 1;
integer cHan;
string stripTags(string data)
{
    while(~llSubStringIndex(data, "$"))
    {
        integer tagBeginning = llSubStringIndex(data, "$");  
        data = llDeleteSubString(data, tagBeginning, (tagBeginning + 1));   
    }
    return llStringTrim(data, STRING_TRIM);
}
string funcName() 
{
    string name = curName;
    if(togglename)
    {
        if(~llSubStringIndex(name, "$n"))
        {
            name = llStringTrim(llList2String(llParseString2List(name, ["$n"], []), 0), STRING_TRIM);
        }
        else
        {
            name = llStringTrim(llList2String(llParseString2List(name, [" "], []), 0), STRING_TRIM);
        }
    }
    else if(~llSubStringIndex(name, "$n"))
    {
        integer inx = llSubStringIndex(name, "$n");
        name = llStringTrim(llDeleteSubString(name, inx, (inx + 1)), STRING_TRIM);
    }
   
   return stripTags(name); 
}
funcDoSpeak(string post) {
    if(llGetSubString(llStringTrim(llToLower(post), STRING_TRIM), 0, 2) == "/me") {
        post = llStringTrim(llDeleteSubString(post, 0, 2), STRING_TRIM); // Delete excess /me, we do not need it.
    }
    string savedName = llGetObjectName();
    // Remove extra backslashes and commands for duplicates.
    if(llGetSubString(post, 0, 0) == "/" && (string)((integer)llGetSubString(post, 1, 1)) == llGetSubString(post, 1,1)) {
        post = llStringTrim(llDeleteSubString(post, 0, 1), STRING_TRIM);
    }
    string postName = funcName();
    list markers = ["!","#",":"];
    string marker;
    // Let's get the name in order, sort out apostrophes.
    if(!postMode) { // Attempted fix for shout multiposting. This is cleared via timer, and if postMode is not FALSE, we don't wanna delete anything.
        if(llListFindList(markers, [llGetSubString(post, 0, 0)]) != -1) {
            marker = llGetSubString(post, 0, 0);
            if(llToLower(llGetSubString(post, 1, 2)) == "'s") {
                if(llGetSubString(llToLower(postName), -1, -1) == "s") {
                    post = llDeleteSubString(post, 1, 2);
                    postName = llStringTrim(postName + "'", STRING_TRIM);
                } else {
                    post = llDeleteSubString(post, 1, 2);
                    postName = llStringTrim(postName + "'s", STRING_TRIM);
                }
            }
            post = llStringTrim(llDeleteSubString(post, 0, 0), STRING_TRIM);
        } else {
            if(llToLower(llGetSubString(post, 0, 1)) == "'s") {
                if(llGetSubString(llToLower(postName), -1, -1) == "s") {
                    post = llDeleteSubString(post, 0, 1);
                    postName = postName + "'";
                } else {
                    post = llDeleteSubString(post, 0, 1);
                    postName = postName + "'s";
                }
            }
            post = llStringTrim(post, STRING_TRIM);
        }
    }
    if(llGetSubString(post, 0, 0) == ",") {
        postName = postName + ",";
        post = llStringTrim(llDeleteSubString(post, 0, 0), STRING_TRIM);
    }
    string me = "/me ";
    if(specialName) {
        llSetObjectName("");
        post = postName + " " + post;
    } else {
        llSetObjectName(postName);
    }
    if(marker == "!" || postMode == 1) {
        if(!postMode) { // Attempted fix for failure to multipost in shout.
            postMode = 1;
            llSetTimerEvent(1.5);
        }
        if(!devMode) {
            llShout(0, me + post);
        } else {
            llOwnerSay("DEV MODE");
            if(!whisper) {
                llSay(0, me + post);
            } else {
                llWhisper(0, me + post);
            }
        }
    } else if(marker == "#" || postMode == 2) {
        if(!postMode) { // Attempted fix for failure to multipost in shout.
            postMode = 2;
            llSetTimerEvent(1.5);
        }
        llWhisper(0, me + "whispers, \"" + post + "\"");
    } else if(marker == ":" && postMode == 0) {
        if(!whisper) {
            llSay(0, me + "says, \"" + post + "\"");
        } else {
            llWhisper(0, me + "says, \"" + post + "\"");
        }
    } else if(postMode == 0) {
        if(!whisper) {
            llSay(0, me + post);
        } else {
            llWhisper(0, me + post);
        }
    }
    llSetObjectName(savedName); // Finished.
}
integer chkPureASCII(string data) 
{
    data = llDumpList2String(llParseStringKeepNulls((data = "") + data, [" "] + allowedSpecials, []), "");
    if(data != llEscapeURL(data))
    {
        return TRUE;
    }
    return FALSE;
}
integer Key2AppChan(key ID, integer App) {
    return 0x80000000 | ((integer)("0x"+(string)ID) ^ App);
}
default
{
    state_entry()
    {
        llListen(4, "", llGetOwner(), "");
        llListen(3, "", llGetOwner(), "");
        llListen(22, "", llGetOwner(), "");
        cHan = llListen(chan, "", llGetOwner(), "");
    }
    timer() {
        llSetTimerEvent(0);
        postMode = FALSE;
    }
    on_rez(integer start_param)
    {
        llOwnerSay(helpStr);
        if(whisper)
        {
            llOwnerSay("You are currently in 'whisper mode'. Your /4 and /3 chat range is 10m. Do '/1 chatrange' without quotes to revert this.");
        }
    }    
    changed(integer change)
    {
        if(change & CHANGED_OWNER)
        { 
            llResetScript();
        }
    }
    listen(integer c, string n, key id, string m)
    {
        if(c == 4)
        {
            if(m != "" && m != " ")
            {
                funcDoSpeak(m); 
            }
        }
        else if(c == 22)
        {
            if(m == "" && m == " ") {
                return;
            }
            string tmp = llGetObjectName();
            string tmpNameOoc;
            if(~llSubStringIndex(curName, "$n"))
            {
                tmpNameOoc = llStringTrim(llDeleteSubString(curName, llSubStringIndex(curName, "$n"), (llSubStringIndex(curName, "$n") + 1)), STRING_TRIM);
            }
            else
            {
                tmpNameOoc = curName;
            }
            if(specialName)
            {
                llSetObjectName("");
                m = llStringTrim(tmpNameOoc+" ("+llKey2Name(llGetOwner())+") OOC: " + m, STRING_TRIM);
            }
            else 
            {
                llSetObjectName(tmpNameOoc+" ("+llKey2Name(llGetOwner())+") OOC");
            }
            llSay(0, m);
            llSetObjectName(tmp); 
        }
        else if(c == 3) 
        {
            if(m == "" && m == " ") {
                return;
            }
            string tmp = llGetObjectName();
            
            if(llGetSubString(m, 0, 0) == "/" && (string)((integer)llGetSubString(m, 1, 1)) == llGetSubString(m, 1, 1))
            {
                m = llDeleteSubString(m, 0, 1);
                m = llStringTrim(m, STRING_TRIM);
            }
            llSetObjectName("");

                if(llGetSubString(m, 0, 0) == "#") 
            {

                    m = llDeleteSubString(m, 0, 0);
                m = llStringTrim(m, STRING_TRIM);
                llWhisper(0, "/me "+m);
            }
            else if(llGetSubString(m, 0, 0) == "!") 
            {
                llSetObjectName("");
                m = llDeleteSubString(m, 0, 0);
                m = llStringTrim(m, STRING_TRIM);
                llShout(0, m);
            }
            else 
            {
                if(!whisper)
                {
                    llSay(0, "/me "+m);
                }
                else
                {
                    llWhisper(0, "/me "+m);
                }
            }
            llSetObjectName(tmp);
        }
        else if(c == chan)
        {
            if(llToLower(m) == "togglename") 
            {
                if(togglename)
                {
                    togglename = FALSE;
                    llOwnerSay("Chatter now uses your characters' full names.");
                }
                else
                {
                    togglename = TRUE;
                    llOwnerSay("Chatter is now using only your characters' first names.");
                }
            }
            else if(llToLower(m) == "togglewhisper" || llToLower(m) == "chatrange")
            {
                if(!whisper)
                {
                    whisper = TRUE;
                    llOwnerSay("/4 & /3 chatrange reduced to 10 meters.");
                }
                else
                {
                    whisper = FALSE;
                    llOwnerSay("/4 & /3 chatrange increased to 20 meters.");
                }

                }
            else if(llGetSubString(llToLower(m),0,3) == "name")
            {
                string tmp = llGetSubString(m, 4, -1);
                curName = llStringTrim(tmp, STRING_TRIM);
                specialName = chkPureASCII(stripTags(curName));
                llOwnerSay("Chatter name now set to: " + curName);
            } else if(llGetSubString(llToLower(m),0,3) == "help") {
                llOwnerSay(instructions);
            }
        }
    }
}
