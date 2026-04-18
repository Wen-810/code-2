CHICK   START   0

FIRST   JSUB    INIT_VAR    . ★ 確保每次重啟遊戲時，數值強制重置
        JSUB    INIT_XY     . 設定起點
        JSUB    CH_XY       . 計算位置
        JSUB    NEWFE

MAIN    JSUB    GTIME       . 倒數計時
        JSUB    DRAW        . 開始繪圖
        JSUB    SHKEY       .. 鍵盤輸入
        JSUB    CH_XY       .. 計算新位置
        JSUB    FE_XY       ...飼料位置
        JSUB    FDRAW       ...畫出飼料
        JSUB    DELAY       ...延遲飼料落下(避免下落太快)
        JSUB    DSCORE      ....記分板
        J       MAIN        .. 迴圈(重複main)
HALT    J       HALT        . 結束

. --- 子程式 ： 開局變數重置 (解決重啟數值錯亂) ---
INIT_VAR LDA    #48         . ASCII 的 '0'
         STCH   TV_H        . 百位數設為 0
         STCH   TV_U        . 個位數設為 0
         STCH   S_VAL       . 分數歸 0
         
         LDA    #54         . ASCII 的 '6'
         STCH   TV_T        . 十位數設為 6  => 這樣時間就一定是 060
         
         LDA    IV_D        
         STA    D_VAL       . 重置初始下落速度
         
         LDA    #0
         STA    F_COUNT     . 重置接到飼料的數量
         STA    SEC_TIC     . 重置計時器
         STA    FETI        . 重置落下延遲
         RSUB

. --- 資料區 ---
GT_TXT  BYTE    C'TIME: '   . 時間文字標籤 (6個字元)
GO_TXT  BYTE    C'GAME OVER' . 勝利/結束文字標籤 (9個字元)
LS_TXT  BYTE    C'YOU LOSE'  . ★ 新增：失敗文字標籤 (8個字元)

. 將 T_VAL 拆分成三個獨立 Byte
TV_H    BYTE    C'0'        . 百位數
TV_T    BYTE    C'6'        . 十位數
TV_U    BYTE    C'0'        . 個位數

GT_X    WORD    0           . 繪圖暫存 X
GT_PTR  WORD    0           . 繪圖暫存指標

NCH_X   WORD    0           . 小雞x位置
NCH_Y   WORD    0           . 小雞y位置 
CH_X    WORD    35          . 預設的小雞x位置
CH_Y    WORD    15          . 預設的小雞y位置
COL_W   WORD    80          . 螢幕寬度
COL_H   WORD    25          . 螢幕高度
BASE    WORD    X'00B800'   . 螢幕起點
SCR_PTR WORD    0           . 目前要寫入的螢幕位址
IMG_PTR WORD    0           . 目前要讀取的圖案位址 (0, 1, 2...)
ROW_CNT WORD    0           . 行計數器 (0-4)
COL_CNT WORD    0           . 列計數器 (0-8)
ONE     WORD    1           . 用於計數+1
NINE    WORD    9           . 小雞圖案行數
FIVE    WORD    5           . 小雞圖案列數
GAP     WORD    71          . 換行修正 (80 - 9)

KEYB    WORD    X'00C000'   .. 鍵盤
LEFT    WORD    X'000041'   .. 65 => A
RIGHT   WORD    X'000044'   .. 68 => D

FE_X    WORD    55          ... 飼料位置X
FEM_X   WORD    0
FEMM_X  WORD    0
FE_Y    WORD    0           ... 飼料位置Y
NFE_X   WORD    0           ... 存飼料位置X
NFE_Y   WORD    0           ... 存飼料位置Y
FE_PTR  WORD    0           ... 飼料位址
FETI    WORD    0           ... 控制飼料延遲(落下速度)

S_TXT   BYTE    C'SCORE: '  . 分數文字標籤 (7個字元)
S_VAL   BYTE    C'0'        . 實際分數數字
S_MVAL  WORD    0
TMP_X   WORD    0           . 繪圖暫存 X
TMP_PTR WORD    0           . 繪圖暫存指標

IV_D    WORD    4000        . 備用的初始延遲數值
D_VAL   WORD    4000        . 運行時的延遲數值
F_COUNT WORD    0           . 接到飼料的累積數量
SPEED_ST WORD   2           . 每接到幾顆要加速 (這裡設為 2)
DEC_VAL WORD    200         . 每次加速要減少的延遲量 (數值越小越快)
MIN_D   WORD    1000        . 設定一個最小延遲量，避免飼料快到接不到
SEC_TIC WORD    0           . 偵測時間流逝的計數器
SEC_LIM WORD    10          . 根據 DELAY 大小，決定多少個迴圈算一秒

. --- 小雞圖案 ---
CH_IMG  BYTE    C'   \|/   '
        BYTE    C' (* ^ *) '
        BYTE    C'  /   \  '
        BYTE    C' /     \ '
        BYTE    C' ------- '

. --- 飼料圖案 ---
FE_IMG  BYTE    C'*'


. --- 子程式 : 落下延遲(速度) ---
DELAY   LDA     D_VAL       ... 數字越大越慢
D_LOOP  SUB     ONE         ... 倒數(DELAY)
        COMP    #0
        JGT     D_LOOP

        LDA     FETI
        ADD     ONE
        STA     FETI
        
        RSUB
        

. --- 子程式 : 移動(讀取鍵盤) ---
SHKEY   LDX     KEYB        .. 將鍵盤位址 (C000) 載入 X 暫存器
        LDCH    0,X         .. 從 C000 讀取目前按下的按鍵到 A 暫存器

        COMP    #65         .. 判斷是否為 'A' (65)
        JEQ     MLIGHT      .. 是 => 跳去向左的邏輯
        COMP    #68         .. 判斷是否為 'D' (68)
        JEQ     MRIGHT      .. 是 => 跳去向右的邏輯
        J       CLR_K       .. 清除

 
CLR_K   CLEAR   A           .. 清除鍵盤緩衝區(避免同一個按鍵被無限重複讀取)
        LDX     KEYB        .. 將C000歸零
        STCH    0,X       
        RSUB


. --- 子程式 : 位址 ---
INIT_XY LDA     CH_Y        .預設小雞位置 Y
        STA     NCH_Y
        LDA     CH_X        .預設小雞位置 X
        STA     NCH_X
        RSUB

MLIGHT  LDA     NCH_X
        SUB     ONE
        COMP    #1          .. 螢幕邊界限制
        JLT     RMAIN
        STA     NCH_X
        J       CLR_K

MRIGHT  LDA     NCH_X
        ADD     ONE
        COMP    #71         .. 螢幕邊界限制
        JGT     RMAIN
        STA     NCH_X
        J       CLR_K


. --- 子程式 ： 計算位址 ---
CH_XY   LDA     NCH_Y       . 位置 (Y)
        MUL     COL_W       . Y * COL_W(螢幕寬度)
        ADD     NCH_X       . + 位置(X)
        ADD     BASE        . + 螢幕起點
        STA     SCR_PTR     . 算出左上角第一個點
        RSUB

. --- 子程式 ： 核心繪圖邏輯 ---
DRAW    LDA     #0
        STA     IMG_PTR     . 初始化圖案指標
        STA     ROW_CNT     . 初始化行計數

ROW_LP  LDA     #0
        STA     COL_CNT     . 初始化列計數

        . 1. 讀取小雞圖案字元寫入螢幕
COL_LP  LDX     IMG_PTR
        LDCH    CH_IMG,X
        LDX     SCR_PTR     . 將目標位址載入 X
        STCH    0,X         . 標準寫法：存入 0 + X 的位址

        . 2. 更新指標
        LDA     IMG_PTR
        ADD     ONE
        STA     IMG_PTR     . 圖案指標 + 1
        
        LDA     SCR_PTR
        ADD     ONE
        STA     SCR_PTR     . 螢幕指標 + 1

        . 3. 檢查列結束沒 (9次)
        LDA     COL_CNT
        ADD     ONE
        STA     COL_CNT
        COMP    NINE
        JLT     COL_LP      . (<9) 沒畫完 9 個字就繼續

        . 4. 換行處理
        LDA     SCR_PTR
        ADD     GAP         . + 16，跳到下一行起點
        STA     SCR_PTR
        
        LDA     ROW_CNT
        ADD     ONE
        STA     ROW_CNT
        COMP    FIVE        . 檢查畫完 5 行沒
        JLT     ROW_LP
        RSUB

. --- 子程式 ： 飼料生成 ---
NEWFE   LDA     FE_X        .... FEM_X += (FE_X * CH_X + NCH_X)*13
        MUL     NCH_X
        ADD     NCH_X
        MUL     #17
        ADD     FE_X
        MUL     #13
        STA     FEM_X

        LDA     FEM_X       .... NFE_X = (FEM_X mod 76) + 3
        DIV     #76
        MUL     #76
        STA     FEMM_X
        LDA     FEM_X
        SUB     FEMM_X
        ADD     #3
        STA     NFE_X

        LDA     NFE_X       .... FE_X = NFE_X
        STA     FE_X

        LDA     #0           
        STA     NFE_Y

        RSUB

FE_XY   LDA     NFE_Y       ... 計算飼料位址
        MUL     COL_W        
        ADD     NFE_X        
        ADD     BASE         
        STA     FE_PTR       
        RSUB

FDRAW   . 1. 擦掉舊飼料
        LDX     FE_PTR
        LDA     #32
        STCH    0,X

        LDA     FETI
        COMP    #5
        JLT     CH_YTOP

        . 2. 更新 Y 座標
        LDA     NFE_Y
        ADD     #1
        STA     NFE_Y

        LDA     #0
        STA     FETI
        
        . 3. 判斷飼料是否掉到小雞頭頂
CH_YTOP LDA     NFE_Y
        COMP    #15         ... 判斷 Y 與 15 (小雞頭頂)
        JEQ     CHECK       ... 相等 => 跳去檢查 X 座標

RET_CHK COMP    #20         ... 判斷 Y 與 20 (小雞底部)
        JGT     RE_SC       ... 大於(*超過小雞底部) => 扣分區

        . 4. 重新計算位址並畫出
        LDA     NFE_Y
        MUL     COL_W
        ADD     NFE_X
        ADD     BASE
        STA     FE_PTR

        LDX     FE_PTR
        LDCH    FE_IMG
        STCH    0,X
        RSUB

. --- 子程式 ： 扣分邏輯 ---
RE_SC   CLEAR   A
        LDCH    S_VAL       . 讀取目前分數
        SUB     #1          . 減 1 
        COMP    #48
        JLT     RST_S

SRE_SC  STCH    S_VAL       . 沒低於 0，存回扣完的分數
        J       NEWFE       . 重新生成飼料

. --- 子程式 ： 碰撞判定與加分邏輯 ---
CHECK   LDA     NFE_X
        SUB     NCH_X       . 計算飼料跟小雞的相對距離
        COMP    #1          . 如果距離小於 1 (掉在左翅膀外)
        JLT     RET_CHK     . 沒接到
        COMP    #7          . 如果距離大於 7 (掉在右翅膀外)
        JGT     RET_CHK     . 沒接到
        
        . --- 成功接到！加分 ---
        CLEAR   A
        LDCH    S_VAL       . 讀取目前分數
        ADD     #1          . 加 1
        COMP    #58         . 檢查是否達 10 (ASCII 58 是 ':')
        JEQ     GAMEOV      . 若達 10 分，跳去顯示 GAME OVER (勝利結局)！
        STCH    S_VAL       . 存回新分數

        . --- 加速邏輯開始 ---
        LDA     F_COUNT     . 累加接到次數
        ADD     ONE
        STA     F_COUNT

        LDA     S_VAL       . 檢查分數是否 >= 5 ('5' 的 ASCII 是 53)
        COMP    #53
        JLT     NEWFE       . 分數小於 5，直接產生新飼料(不加速)

        LDA     F_COUNT     . 分數滿 5 分了，檢查是否接到 2 顆
        COMP    SPEED_ST
        JLT     NEWFE       . 還沒滿 2 顆，跳過

        . --- 執行加速 ---
        LDA     #0          . 歸零計數器，重新算下兩顆
        STA     F_COUNT
        
        LDA     D_VAL       . 減少延遲數值
        SUB     DEC_VAL
        COMP    MIN_D       . 檢查是否快過頭了
        JLT     SET_MIN     . 太快了就維持最小值
        STA     D_VAL
        J       NEWFE

SET_MIN LDA     MIN_D
        STA     D_VAL
        J       NEWFE
        
RST_S   LDA     #48         . ASCII 的 '0'
        STCH    S_VAL
        J       NEWFE


. --- 子程式 ： 繪製分數板 ---
DSCORE  LDA     #0
        STA     TMP_X

        LDA     BASE
        ADD     #80
        STA     TMP_PTR    . 把螢幕指標設在 BASE 左上角

DS_LP   LDX     TMP_X
        LDCH    S_TXT,X    . 讀取 'SCORE: ' 的字元到 A 
        LDX     TMP_PTR    . 將螢幕目標位址載入 X
        STCH    0,X        . 把 A 的字元畫到螢幕上！
        
        LDA     TMP_PTR
        ADD     ONE
        STA     TMP_PTR    . 螢幕指標 + 1 (準備畫下一格)

        LDA     TMP_X
        ADD     ONE
        STA     TMP_X
        COMP    #7         . 檢查 7 個字元畫完沒
        JLT     DS_LP
        
        . 畫出數字
        LDA     BASE
        ADD     #87         . 緊接在文字後面
        STA     TMP_PTR
        LDX     TMP_PTR
        CLEAR   A
        LDCH    S_VAL      . 讀取目前分數數字
        STCH    0,X        . 畫到螢幕上
        RSUB


. --- 子程式 ： 繪製正計時 ---
GTIME   LDA     SEC_TIC
        ADD     ONE
        STA     SEC_TIC
        COMP    SEC_LIM
        JLT     SHOW_T      . 還沒到一秒，直接去顯示目前的數字

        LDA     #0          . 到一秒了，重置計數器
        STA     SEC_TIC
        
        . --- 倒數邏輯：處理個位數 ---
        CLEAR   A
        LDCH    TV_U        
        SUB     #1          
        COMP    #47         
        JEQ     DECTEN      . 低於 0，跳去向十位數借位！
        STCH    TV_U        
        J       SHOW_T      

        . --- 倒數邏輯：處理十位數借位 ---
DECTEN  LDA     #57         . 個位數歸 '9' 
        STCH    TV_U

        CLEAR   A
        LDCH    TV_T        
        SUB     #1          
        COMP    #47         
        JEQ     LOSE        . ★ 改變：時間到了，跳去 LOSE (失敗結局)！
        STCH    TV_T        

SHOW_T  LDA     #0          
        STA     GT_X
        LDA     BASE        
        STA     GT_PTR
        
GT_LP   LDX     GT_X        
        LDCH    GT_TXT,X    
        LDX     GT_PTR      
        STCH    0,X         
        
        LDA     GT_PTR
        ADD     ONE
        STA     GT_PTR
        LDA     GT_X
        ADD     ONE
        STA     GT_X
        COMP    #6          
        JLT     GT_LP

        . --- 繪製時間數字部分 ---
        LDX     GT_PTR      
        LDCH    TV_H
        STCH    0,X
        
        LDA     GT_PTR      
        ADD     ONE
        STA     GT_PTR
        LDX     GT_PTR      
        LDCH    TV_T
        STCH    0,X

        LDA     GT_PTR      
        ADD     ONE
        STA     GT_PTR
        LDX     GT_PTR      
        LDCH    TV_U
        STCH    0,X
        
        RSUB

. --- 子程式 ： 清空全螢幕 (填滿空白) ---
CLRSCR  LDA     BASE
        STA     TMP_PTR     . 從螢幕最左上角開始
        LDA     #0
        STA     TMP_X       . 計數器歸零
        
CS_LP   LDX     TMP_PTR
        LDA     #32         . 讀取空白字元 (ASCII 32)
        STCH    0,X         . 寫入螢幕
        
        LDA     TMP_PTR
        ADD     ONE
        STA     TMP_PTR     . 螢幕指標 + 1
        
        LDA     TMP_X
        ADD     ONE
        STA     TMP_X       . 計數器 + 1
        COMP    #2000       . 檢查 80 * 25 = 2000 格清完了沒
        JLT     CS_LP       . 沒清完就繼續迴圈
        RSUB


. --- 子程式 ： 繪製 GAME OVER (勝利滿 10 分) ---
GAMEOV  JSUB    CLRSCR      . 先洗白畫面

        LDA     #0
        STA     GT_X        . 借用 GT_X 當作文字計數器
        
        LDA     BASE
        ADD     #995        . 螢幕正中央！ (GAME OVER 9個字)
        STA     GT_PTR      . 借用 GT_PTR 當作螢幕位址指標

GO_LP   LDX     GT_X
        LDCH    GO_TXT,X    . 讀取 'GAME OVER' 的字元
        LDX     GT_PTR
        STCH    0,X         . 畫到螢幕正中央
        
        LDA     GT_PTR
        ADD     ONE
        STA     GT_PTR      
        
        LDA     GT_X
        ADD     ONE
        STA     GT_X        
        COMP    #9          . 檢查 9 個字元畫完沒
        JLT     GO_LP       
        
        J       HALT        . 畫完之後進入死迴圈


. --- 子程式 ： 繪製 YOU LOSE (★ 新增：時間倒數歸零) ---
LOSE    JSUB    CLRSCR      . 一樣先洗白畫面

        LDA     #0
        STA     GT_X        . 借用 GT_X 當作文字計數器
        
        LDA     BASE
        ADD     #996        . 螢幕正中央！ (YOU LOSE 8個字，往右微調一格對齊)
        STA     GT_PTR      

LS_LP   LDX     GT_X
        LDCH    LS_TXT,X    . 讀取 'YOU LOSE' 的字元
        LDX     GT_PTR
        STCH    0,X         . 畫到螢幕正中央
        
        LDA     GT_PTR
        ADD     ONE
        STA     GT_PTR      
        
        LDA     GT_X
        ADD     ONE
        STA     GT_X        
        COMP    #8          . 檢查 8 個字元畫完沒
        JLT     LS_LP       
        
        J       HALT        . 畫完之後進入死迴圈


RMAIN   RSUB

        END     FIRST