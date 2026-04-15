% ==========================    =======================================
% Winner LAB, Ajou University
% Distance-based HO Parameter Optimization Protocol Code
% Prototype    : system_parameter.m
% Type         : MATLAB code
% Author       : Jongtae Lee
% Revision     : v1.0   2024.06.04
% Modified     : 2024.07.01
% =================================================================

%% Set1-600km Scenario
cellRadius = 23120;  %25000, 23120
cellISD = 40045.0147; % 43301.2702, 40045.0147

%% User Equipment Configuration
% UE_num = 251; % 26, 251
if ~exist('UE_TEST_SINGLE', 'var')
	UE_TEST_SINGLE = false;                  % true: 단말 1개 테스트 모드
end
if ~exist('UE_TEST_X', 'var')
	UE_TEST_X = round(cellRadius * 0.5);    % 1-UE 모드일 때 x 위치 [m]
end

if UE_TEST_SINGLE
	UE_x = UE_TEST_X;
else
	UE_x = randi([0, cellRadius], 1, 5000); % 랜덤 UE 위치 생성
end
% UE_x = 17340; % RSRP용 centre, mid, edge 위치별 (10000km, 17340m, 23120m)
UE_y = 80090.0293; % 86602.5404, 80090.0293


%% General Parameter
FREQ = 2e9;                                     % 2GHz [Frequency band]
BW = 20e6;                                      % 20 MHz [Bandwidth]
c = 299792458;                                  % light speed
BOLTZ = 1.38064852e-23;                         % Boltzmann constant [J/K]
Tx_g = 30;
AP = 2;
eirp = 34;
altit = 600000;

%% Filtering Parameters
% k_filter = 2; % SINR 필터용 k 개수
k_rsrp = 4;   % RSRP 필터 계수 설정 (가중치 고려 (이전값/현재값), 0: 0%/100% | 2: 30%/70% | 4: 50%/50% | 8: 75%/25%

%% Simulation Time Configuration
START_TIME = 0;                 % 시작 시간 0초
SAT_SPEED = 7560;
TOTAL_TIME = 173.21 / 7.56;                     % 64.95, 86.6, 129.9, 173.2, 216.5
SAMPLE_TIME = 0.2;                              % 10ms: measurement epoch 
STOP_TIME = TOTAL_TIME;                         % 총 시뮬레이션 시간
SITE_MOVE = SAT_SPEED * SAMPLE_TIME;            % moving distance (deterministic)
TIMEVECTOR = 0:SAMPLE_TIME:STOP_TIME;           % Create time vector

%% Simulation Episode Set
EPISODE = 1;                                   % SIMULATION EPISODE
Scenario_ = 'case 1';
fading = 'Rural';
% fading = 'Urban';
% fading = 'DenseUrban';

%% ---- Human-friendly inputs (units you type) ----
SAT_GROUNDSPEED_KMPS = 7.56;   % 위성 지상투영 속도 [km/s]
UE_SPEED_UNIT        = 'kmh';  % UE set_mobility는 km/h 받도록 유지 (기존 그대로)

%% ---- Coordinates / radius are in meters (권장) ----
POSITION_UNIT = 'm';           % 좌표/반지름 기본 단위 메모(참고용)

%% ---- CHO Message Procedure Parameters (case 2: MTD_A3_CHO_rev) ----
% D2 trigger parameters (3GPP Event D2)
D2_HYS = 0;                         % [m] hysteresisLocation
D2_THRESH2 = cellRadius;            % [m] distanceThreshFromReference2
D2_THRESH1 = 18300;                 % [m] distanceThreshFromReference1 (D2-CFRA/RAL 공통)
D2_THRESH1_CFRA = D2_THRESH1;       % backward-compat alias
D2_THRESH1_RACHLESS = D2_THRESH1;   % backward-compat alias

CHO_MSG_ENABLE_PROC_DELAY = true;   % false면 PROC_* 지연을 0으로 처리
CHO_MSG_ENABLE_CTRL_QUEUE = true;   % false면 제어메시지(MR/HO_REQ/ACK/CMD/CFRA/HOC) 큐 비활성
CHO_MSG_ENABLE_DYN_GRANT_QUEUE = true; % false면 dynamic grant 큐 모델 비활성(즉시 처리 근사)

CHO_MSG_C_LIGHT = 299792458;   % [m/s] propagation speed
CHO_MSG_MIT_INCLUDE_PROCESSING = true; % true면 MIT_total에 RRC/message processing 지연 포함
CHO_MSG_PROC_RAND_MIN = 0.010; % [s] RRC/message processing delay random min
CHO_MSG_PROC_RAND_MAX = 0.016; % [s] RRC/message processing delay random max
CHO_MSG_PROC_SERV = 0.001;     % [s] serving-node processing delay
CHO_MSG_PROC_TARG = 0.001;     % [s] target-node processing delay
CHO_MSG_PROC_EXEC_UE = 0.001;  % [s] CHO CMD 수신 후 UE execution 처리시간
CHO_MSG_PROC_INTERRUPT = 0.001;  % [s] execution 만족 후 preamble/UL grant 송신 전 대기
CHO_MSG_PROC_UE_HC = 0.001;    % [s] UE가 RSP 수신 후 HO COMPLETE 송신까지 처리시간
CHO_MSG_PROC_GRANT_SCHED = 0.001; % [s] dynamic grant 스케줄러 처리시간(gNB)
CHO_MSG_RACHLESS_GRANT_MODE = 'preallocated'; % 'preallocated' | 'dynamic'
CHO_MSG_DYN_GRANT_FAIL_ENABLE = true; % true면 dynamic grant 실패 이벤트 모델링
CHO_MSG_DYN_GRANT_FAIL_PROB = 0.15;   % dynamic grant 실패 확률
CHO_MSG_DYN_GRANT_FALLBACK_TO_RACH = true; % 실패 시 CFRA(RACH) fallback 수행
CHO_MSG_PROC_FALLBACK_RACH = 0.001;   % [s] dynamic 실패 후 RACH fallback 시작 전 처리시간
CHO_MSG_DYN_GRANT_PERIOD = max(0.002, SAMPLE_TIME/5); % [s] dynamic grant 재전송 주기(샘플링 해상도 고려)
CHO_MSG_DYN_GRANT_VALIDITY = max(0.01, SAMPLE_TIME*2); % [s] UE 수신 grant 유효시간(샘플링 간격보다 충분히 크게)
CHO_MSG_DYN_GRANT_MAX_TX = 8;         % dynamic grant 최대 전송 횟수
CHO_MSG_DYN_GRANT_PREP_SEND = true;   % true면 prep 이후부터 dynamic grant를 주기 송신(UE는 exec 이후 수신분 사용)
CHO_MSG_RB_PER_GRANT_TX = 1;          % grant 1회 전송당 RB 사용량 모델
CHO_MSG_T304 = 1.0;                   % [s] HO supervision timer(T304) (50, 100, 150, 200, 500, 1000, 2000, 10000 ms / TS38331-cellgroupconfig-spcellconfig-reconfigurationwithsync)
CHO_MSG_T310 = 1.0;                   % [s] RLF timer(T310)
CHO_MSG_DYN_TIMEOUT_ACTION = 'fallback'; % 'reestablish' | 'fallback'
CHO_MSG_QUEUE_LOG = false;            % true면 dynamic grant queue 상태를 터미널에 출력
CHO_MSG_VERBOSE = false;       % true: print TX/RX timestamps

% LOS/NLOS-aware delay model (3GPP-inspired, paper-friendly)
CHO_MSG_DELAY_MODEL_ENABLE = true;      % false면 pure geometric delay만 사용
CHO_MSG_USE_LOSNLOS = true;             % false면 LOS로 고정
CHO_MSG_APPLY_LOSNLOS_ON_XN = false;    % false면 Xn은 LOS 고정
CHO_MSG_XN_P_LOS = 1.0;                 % Xn에 LOS/NLOS 적용 시 LOS 확률
CHO_MSG_USE_GET_LOSS_TABLE = true;      % true면 GET_LOSS.m의 elev-bin LOS 확률표 사용
CHO_MSG_LOS_TABLE_SCENARIO = fading;    % 'Rural' | 'Urban' | 'DenseUrban'

% LOS probability model vs elevation angle: p=1/(1+a*exp(-b*(elev-theta0)))
CHO_MSG_LOS_PROB_A = 9.61;
CHO_MSG_LOS_PROB_B = 0.16;
CHO_MSG_LOS_PROB_THETA0 = 9.61;

% NLOS excess delay: ((kappa-1)*d/c) + tau_mp
CHO_MSG_NLOS_KAPPA_MEAN = 1.20;         % path-length inflation mean (>1)
CHO_MSG_NLOS_KAPPA_LN_SIGMA = 0.25;     % lognormal sigma
CHO_MSG_NLOS_TAU_MEAN = 0.0005;         % [s] multipath mean excess (e.g., 0.5 ms)
CHO_MSG_NLOS_EXCESS_MAX = 0.008;        % [s] cap for numerical/physical sanity
