SD_CRAFTQUEUE_LOADED = false
SD_CRAFTQUEUE_CANCELED = false
SD_CRAFTQUEUE_LBTN_HOOKED = false

function SD_CRAFTQUEUE_ON_INIT(addon, frame)
  SD_CRAFTQUEUE_LBTN_HOOKED = false
  
  if SD_CRAFTQUEUE_LOADED then
    return;
  end
  
  _G['SD_OLD_CRAFT_DETAIL_CRAFT_EXEC_ON_FAIL'] = CRAFT_DETAIL_CRAFT_EXEC_ON_FAIL;
  _G['CRAFT_DETAIL_CRAFT_EXEC_ON_FAIL'] = SD_CRAFT_DETAIL_CRAFT_EXEC_ON_FAIL;
  
  _G['SD_OLD_CRAFT_DETAIL_CRAFT_EXEC_ON_START'] = CRAFT_DETAIL_CRAFT_EXEC_ON_START;
  _G['CRAFT_DETAIL_CRAFT_EXEC_ON_START'] = SD_CRAFT_DETAIL_CRAFT_EXEC_ON_START;
  
  ui.SysMsg('-> sd_craftqueue');
  
  SD_CRAFTQUEUE_LOADED = true
end

function SD_CRAFT_DETAIL_CRAFT_EXEC_ON_START(frame, msg, str, time)
  SD_OLD_CRAFT_DETAIL_CRAFT_EXEC_ON_START(frame, msg, str, time);
  
  if SD_CRAFTQUEUE_LBTN_HOOKED == false then
    local ta = ui.GetFrame('timeaction');
    local btn = GET_CHILD(ta, 'cancel', 'ui::CButton');
    btn:SetEventScript(ui.LBUTTONUP, 'SD_CANCEL_TIME_ACTION');
    SD_CRAFTQUEUE_LBTN_HOOKED = true;
  end
end

function SD_CANCEL_TIME_ACTION(frame)
  SD_CRAFTQUEUE_CANCELED = true;
  CANCEL_TIME_ACTION(frame);
end

function SD_CRAFT_DETAIL_CRAFT_EXEC_ON_FAIL(frame, msg, str, time)
  imcSound.PlaySoundEvent('sys_item_jackpot_get');
  
  if SD_CRAFTQUEUE_CANCELED == true then
    SD_CRAFTQUEUE_CANCELED = false;
    SD_OLD_CRAFT_DETAIL_CRAFT_EXEC_ON_FAIL(frame, msg, str, time);
    return;
  end
  
  frame = ui.GetFrame(frame:GetUserValue("UI_NAME"))
  if frame:GetUserIValue("MANUFACTURING") ~= 1 then
    return;
  end

  local queueFrame = ui.GetFrame("craftqueue");
  local bg = queueFrame:GetChild("bg");
  local firstChild = bg:GetChildByIndex(1);
  local recipeType = firstChild:GetUserIValue("RECIPE_TYPE");
  local totalCount = firstChild:GetUserValue("TOTAL_COUNT");
  
  if recipeType == nil then
    frame:SetUserValue("MANUFACTURING", 0);
    SetCraftState(0)
    return;
  end

  local idSpace = frame:GetUserValue("IDSPACE");
  local recipecls = GetClassByType(idSpace, recipeType);
  local resultlist = session.GetTempItemIDList();
  local cntText = string.format("%s %s", recipecls.ClassID, totalCount);

  for index=1, 5 do
    local clsName = "Item_"..index.."_1";
    local itemName = recipecls[clsName];
    local recipeItemCnt, recipeItemLv = GET_RECIPE_REQITEM_CNT(recipecls, clsName);
    local invItem = session.GetInvItemByName(itemName);
    if 0 ~= recipeItemCnt and 0 == IS_EQUIPITEM(itemName) then 
      if nil ~= invItem and invItem.count < (recipeItemCnt * totalCount) then
        ui.AddText("SystemMsgFrame", ClMsg('NotEnoughRecipe'));
        CLEAR_CRAFTQUEUE(queueFrame);
        frame:SetUserValue("MANUFACTURING", 0);
        SetCraftState(0)
        return;
      end
    end
  end

  item.DialogTransaction("SCR_ITEM_MANUFACTURE_" .. idSpace, resultlist, cntText);
end
