/*
    Post Order system

    version: 1.3
*/
/*
    Instructions:
        - Touch object containing script for a menu, follow instructions in dialog menus.
        
        Features:
        - Easily add players. CSV format, make sure to save it in a notecard. Wipe & re-add to change order.
        - Automatically keeps track of whose turn it is (chat object character names must match exactly, otherwise manual turn skip is required)
        - Quick wipe of post order to create new one.
*/

// Integer vars

integer page = 1;
integer posInList = 0;

// Float vars

float timeout = 120.0;

// String vars

string chosenOption;

// Vectors

vector colour = <1.0,1.0,0.0>;

// Communication

integer menuChannel = -10;
integer menuListener;

// Lists

list queue;
list mainMenu = ["Skip","Add","Remove","Wipe","Cancel"];

// Keys



// Functions

openMainMenu()
{
    llListenRemove(menuListener);
    chosenOption = "";
    menuListener = llListen(menuChannel, "", llGetOwner(), "");
    llDialog(llGetOwner(), "Choose your option", orderButtons(mainMenu), menuChannel);
    llSetTimerEvent(timeout);
}
list orderButtons(list buttons)
{
    return llList2List(buttons, -3, -1) + llList2List(buttons, -6, -4)
         + llList2List(buttons, -9, -7) + llList2List(buttons, -12, -10);
}
parseText()
{
    integer x = 0;
    integer y = llGetListLength(queue);
    if(posInList == y)
    {
        posInList = 0;
    }
    if(y == 0)
    {
        llSetText("", <1,1,1>, 1);
        return;
    }
    list parse;
    do
    {
        string name = (string)(x+1) + ": " + llList2String(queue, x);
        if(posInList == x)
        {
            name = "👉 " + name;
        }
        parse += [name];
        ++x;
    }
    while(x < y);
    llSetText(llDumpList2String("POST ORDER\n-------\n" + parse, "\n"), colour, 1);
}
reset()
{
    llSetTimerEvent(0);
    chosenOption = "";
    llListenRemove(menuListener);
}
wipe()
{
    queue = [];
    posInList = 0;
    reset();
    parseText();
}
integer findPerson(string name, key id)
{
    name = llToLower(name);
    if(~llSubStringIndex(name, ") ooc"))
    {
        // Do not prog for OOC chatter.
        return FALSE;
    }
    string chk = llList2String(queue, posInList);
    if(~llSubStringIndex(llToLower(chk), "npc") && llGetOwnerKey(id) == llGetOwner())
    {
        // Prog if it's NPC turn and owner posts.
        return TRUE;
    }
    if(~llSubStringIndex(name, llToLower(chk)))
    {
        return TRUE;
    }
    return FALSE;
}

default
{
    state_entry()
    {
        parseText();
        llListen(0, "", "", "");
    }

    on_rez(integer rez)
    {
        llResetScript();
    }

    timer()
    {
        reset();
    }

    touch_start(integer t)
    {
        if(llDetectedKey(0) != llGetOwner())
        {
            return;
        }
        openMainMenu();
    }

    listen(integer channel, string name, key id, string message)
    {
        if(channel == menuChannel && id == llGetOwner())
        {
            if(chosenOption == "")
            {
                // If no chosen option is selected, we're at the main menu.
                if(message == "Cancel")
                {
                    reset();
                    llDialog(llGetOwner(), "Cancelled!", ["OK"], menuChannel);
                }
                else if(message == "Skip")
                {
                    ++posInList;
                    if(posInList >= llGetListLength(queue))
                    {
                        posInList = 0;
                    }
                    parseText();
                    reset();
                }
                else if(message == "Add")
                {
                    chosenOption = message;
                    llSetTimerEvent(timeout);
                    llTextBox(
                        llGetOwner(), 
                        "Add people to queue separated by commas. Example: Eivor,Wesley,Effie\nType 'cancel' without quotes to cancel", 
                        menuChannel
                    );
                }
                else if(message == "Remove")
                {
                    if(llGetListLength(queue) == 0)
                    {
                        reset();
                        llDialog(llGetOwner(), "Queue is empty.", ["OK"], menuChannel);
                        return;
                    }
                    chosenOption = message;
                    llSetTimerEvent(timeout);
                    llTextBox(
                        llGetOwner(), 
                        "Remove people from queue separated by commas. Example: Eivor,Wesley,Effie\nType 'cancel' without quotes to cancel", 
                        menuChannel
                    );
                }
                else if(message == "Wipe")
                {
                    chosenOption = message;
                    llDialog(llGetOwner(), "You are about to wipe the list. Are you sure?", orderButtons(["Yes", "No"]), menuChannel);
                    llSetTimerEvent(timeout);
                }
            }
            else if(chosenOption == "Add")
            {
                if(llToLower(message) == "cancel")
                {
                    reset();
                    llDialog(llGetOwner(), "Cancelled!", ["OK"], menuChannel);
                }
                else
                {
                    list tmp = llCSV2List(message);
                    integer x = 0;
                    integer y = llGetListLength(tmp);
                    do
                    {
                        string name = llStringTrim(llList2String(tmp, x), STRING_TRIM);
                        if(name != "" && name != " ")
                        {
                            queue += [name];
                        }
                        ++x;
                    }
                    while(x<y);
                    reset();
                    parseText();
                    llDialog(llGetOwner(), "Done!", ["OK"], menuChannel);
                }
            }
            else if(chosenOption == "Remove")
            {
                list tmp = llCSV2List(message);
                integer x = 0;
                integer y = llGetListLength(tmp);
                list tmpQueue = queue;
                integer nxtPos = posInList;
                string next = llList2String(tmpQueue, nxtPos);
                do
                {
                    string name = llStringTrim(llList2String(tmp, x), STRING_TRIM);
                    if(name != "" && name != " ")
                    {
                        if(name == next)
                        {
                            // Make sure that we can progress the list sanely.
                            ++nxtPos;
                            next = llList2String(tmpQueue, nxtPos);
                        }
                        integer find = llListFindList(queue, [name]);
                        if(find != -1)
                        {
                            queue = llDeleteSubList(queue, find, find);
                        }
                    }
                    ++x;
                }
                while(x<y);
                // Reuse nxtPos to find where to reset to.
                nxtPos = llListFindList(queue, [next]);
                if(nxtPos == -1)
                {
                    // If there's no-one or we can't find it, reset!
                    posInList = 0;
                }
                else
                {
                    // Otherwise set posInList.
                    posInList = nxtPos;
                }
                reset();
                parseText();
                llDialog(llGetOwner(), "Done!", ["OK"], menuChannel);
            }
            else if(chosenOption == "Wipe")
            {
                if(message == "Yes")
                {
                    wipe();
                }
                else
                {
                    reset();
                    llDialog(llGetOwner(), "Cancelled!", ["OK"], menuChannel);
                }
            }
        }
        else if(channel == 0)
        {
            if(llGetAgentSize(id) != ZERO_VECTOR)
            {
                return;
            }
            if(findPerson(name, id))
            {
                ++posInList;
                parseText();
            }
        }
    }
}
