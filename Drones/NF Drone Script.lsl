/*
    Drone status text for New Frontiers.
    // INSTRUCTIONS \\
    When you have configured the script by editing the variables below, you will give commands on
    channel 1.
    It is this format: /1 id command value
    Example: /1 combatdrone hp 15
    The above example sets drone HP to 15.
    When not attached to your avatar, the script will track its distance from you in the hover text.
    
    // COMMANDS \\
    hp X - Sets drone hp. Cannot exceed max HP, cannot go below zero. Example: /1 combatdrone hp 15
    
    status leash/deploy - Sets drone status to [Leashed] or [Deployed]. Example: /1 combatdrone status deploy
    
    // EDITING \\
    Edit the variables below to get started, don't forget to save.
*/
// EDITABLE VARIABLES \\
string characterName = "Iua"; // Your character's name, the drone operator.
integer hp = 27; // This should be equal to max HP. DO NOT use quotes ("), or decimals.
integer maxHp = 27; // Drone max HP. DO NOT use quotes ("), or decimals.
string name = "Mert"; // Your drone's name.
string title = "<Iua's Scout Drone>"; // Title underneath drone name. Can be anything.
string id = "scoutdrone"; // Unique chat cmd ID your drone has, in case you use multiple.

// DO NOT EDIT BEYOND THIS POINT \\
string status = "[Leashed]";
vector color = <1,1,0>;
string distance;
updateText() {
    string txt = name + "\n" + title + "\nHP: " + (string)hp + "/" + (string)maxHp + "\nStatus: " + status + "\nDistance from "+ characterName +": " + distance;
    llSetText(txt, color, 1);
}
default
{
    state_entry()
    {
        llListen(1, "", llGetOwner(), "");
        updateText();
        llSetTimerEvent(1);
    }
    
    timer() {
        llSetTimerEvent(0);
        list tmp = llParseStringKeepNulls(
            (string)llVecDist(
                llGetPos(),
                (vector)llList2String(
                    llGetObjectDetails(llGetOwner(), [OBJECT_POS]),
                    0
                )
            ),
            ["."],
            []
        );
        distance = llList2String(tmp, 0) + "." + llGetSubString(llList2String(tmp, 1),0,0) + "m";
        updateText();
        llSetTimerEvent(1);
    }
    
    listen(integer c, string n, key uuid, string m) {
        m = llToLower(m);
        list cmd = llParseStringKeepNulls(llStringTrim(m, STRING_TRIM), [" "], []);
        if(llList2String(cmd, 0) != id) {
            return;
        }
        string option = llList2String(cmd, 1);
        if(option == "hp") {
            hp = (integer)llList2String(cmd, 2);
            if(hp < 0) {
                hp = 0;
            } else if(hp > maxHp) {
                hp = maxHp;
            }
        } else if(option == "status") {
            string s = llList2String(cmd, 2);
            if(s == "leash") {
                status = "[Leashed]";
            } else if(s == "deploy") {
                status = "[Deployed]";
            }
        }
        
        updateText();
    }
}
