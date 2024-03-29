	PROGRAM EBTABL
C GENERATES AN ATOMIC MASS TABLE FOR CASCADE
C EB(NN,IZ) = BINDING ENERGY IN MEV
C IZ = 1,144 ATOMIC NUMBER
C NN = 1,128 NEUTRON NUMBER ABOVE THE PROTON DRIP LINE DEFINED
C BY NPDRIP(IZ)
C PUEHLHOFER	12/75	1/77	10/77

C F.Zwarts	1) Added ANSI FORTRAN'77 OPEN and CLOSE
C Jul-1982		statements for file 10 (storage on disk).
C K.V.I.	2) Changed KOPT=4 to read from KVI masstable.
C		3) Changed formatted reads in ANSI FORTRAN'77 free formatted
C			reads, except for character input.
C		4) Some general cleanup using FORTRAN'77
c Nov-2000 M.Yosoi   Rev. for IBM/AIX-xlf

	DIMENSION EB(128,144), EBLD(128), NPD(144), NND(144)
	DIMENSION IV(128),ABW(128),PLOT(45,100)
	DIMENSION DELTA(14)
	CHARACTER*1 BLANK,STAR,PLUS,IK,MLYS,MHILF,PLOT
	CHARACTER*2 IV
	PARAMETER(BLANK=' ',STAR='*',IK='I',MLYS='L',MHILF='H',PLUS='+')
cc	character*80 file_name

	DO 9920 IZ=1,144
	NPD(IZ) = NPDRIP(IZ)
9920	NND(IZ) = NNDRIP(IZ)
	DO 9921 NN=1,128
9921	   EB(NN,IZ) = 0
C INPUT
	READ *, KOPT,KPRINT,KDISC
C KOPT=1	THEORETICAL MASSES FOR ALL PARTICLE-STABLE NUCLEI
C	FROM THE MYERS-SWIATECKI MASS FORMULA
C	WITH THE LYSEKIL CONSTANTS (ARKIV FOR FYSIK 36 (1966) 343
C KOPT=2	THEORETICAL MASSES CALCULATED USING THE DROPLET MODEL
C	MASS FORMULA BY HILF ET AL. NUCL.PHYS. A203 (1973) 627
C KOPT=4	READ-IN MASSES (MEASURED AND EXTRAPOLATED)
C KOPT=5	COMPARISON OF THEORETICAL (MYERS-SWIATECKI) AND
C	MEASURED MASSES (ONLY LINEPRINTER OUTPUT)
C KOPT=6	SAME AS 5 WITH HILF MASSES

C KPRINT /= 0 FOR OUTPUT ON LINEPRINTER
C KDISC /= 0 FOR STORAGE ON DISC

	GO TO (30,30,30,40,40,40), KOPT

C CALCULATION OF LIQUID-DROP MASSES
30	DO 32 IZ=1,144
	DO 32 NN=1,128
	N = NPD(IZ) - 1 + NN
	IF (N.GT.NND(IZ)) GO TO 32
	IA = IZ + N
	IF (KOPT.EQ.1) CALL EBLYS(IZ,IA,EBX,EXCS,SHLL,2,2)
	IF (KOPT.EQ.2) CALL EBHILF(IZ,IA,EBX)
	EB(NN,IZ) = EBX
32	CONTINUE

	IF (KOPT.LE.3) GO TO 50

C INPUT OF EXPERIMENTAL VALUES FROM MASSTABLE
cc40	CALL eloss_path('MASSTABLE',file_name)
40	OPEN(UNIT=1,FILE='MASSTABLE',STATUS='OLD')
cc	OPEN(UNIT=1,FILE=file_name,STATUS='OLD')
c     1	,READONLY,SHARED	! Not ANSI FORTRAN'77
c     1	)
	READ(1,'(I5)') NNUCLI
	DO 42 I=1,NNUCLI
		READ (1,41) IZ,N,EXCS
41		FORMAT (2I3,F9.2)
C IZ = ATOMIC NUMBER, IA = MASS NUMBER, N = Neutron number
C MASS EXCESS EXCS (IN keV)
		IA = N + IZ
		IF (IA.EQ.0) GO TO 42
		IF (IZ.LE.0 .OR. IZ.GT.144) GO TO 42
		IF (N.LT.NPD(IZ) .OR. N.GT.NND(IZ)) GO TO 42
		NN = N - NPD(IZ) + 1
		EB(NN,IZ) = N*8.07169 + IZ*7.28922 - EXCS/1000
42		CONTINUE		
	CLOSE(UNIT=1)
C ADDITIONAL EXTRAPOLATED MASSES
43	IF (KOPT.GE.5) GO TO 70
44	READ (*,45,END=49) MF, IZ, IAMIN, DELTA
C	MF (=L FUER LYSEKIL, H FUER HILF) BISHER NICHT BENUTZT
45	FORMAT (A1,I4,I5,14F5.1)
	IF (IZ.EQ.0) GO TO 49
	DO 46 I=1,14
	IF (DELTA(I).GE.5.) GO TO 44
	IA = IAMIN - 1 + I
	N = IA - IZ
	IF (N.LT.NPD(IZ) .OR. N.GT.NND(IZ)) GO TO 46
	NN = N - NPD(IZ) + 1
	CALL EBLYS (IZ,IA,EBX,EXCS,SHLL,2,2)
	EB(NN,IZ) = EBX + DELTA(I)
46	CONTINUE
	GO TO 44

49	WRITE(6,*)'KOPT',KOPT
	IF (KOPT.GE.5) GO TO 70

C OUTPUT ON LINEPRINTER
50	IF (KPRINT.EQ.0) GO TO 60
	PRINT 57, KOPT
	IZMAX = 144
	IF (KOPT.GE.4) IZMAX = 93
	DO 55 IZ=1,IZMAX
C BESTIMMUNG VON NNMIN,NNMAX
	DO 51 NN=1,128
	NNMIN = NN
	IF (EB(NN,IZ).GT.0.001) GO TO 52
51	CONTINUE
52	DO 53 NN=NNMIN,128
	NNMAX = NN
	IF (EB(NN,IZ).LE.0.001) GO TO 54
53	CONTINUE
	NNMAX = 129

54	NNMAX = NNMAX - 1
	NMIN = NPD(IZ) - 1 + NNMIN
	IAMIN = IZ + NMIN
	PRINT 58, IZ,NMIN,IAMIN
	PRINT 59, (EB(NN,IZ),NN=NNMIN,NNMAX)
55	CONTINUE
	PRINT 56
56	FORMAT (1H1)
57	FORMAT (I4)
58	FORMAT ('0IZ =',I4,'    NMIN =',I4,'    IAMIN =',I4)
59	FORMAT (13(10X,5F8.1,2X,5F8.1/))

C STORAGE OF THE ARRAY EB IN BLOCKS OF 1024 WORDS
C ON DISC (TOTAL 18K, 72 KBYTES)
60	WRITE(6,*)'KDISC',KDISC
	IF (KDISC.EQ.0) GO TO 100
	OPEN (UNIT=10,FILE='EBTABLE.DAT',STATUS='UNKNOWN')
c     1	,FORM='UNFORMATTED')

	DO 61 K=1,18
		IZMIN = (K-1)*8 + 1
		IZMAX = K*8
61		WRITE (10,'(5g15.7)') 
     1                       ((EB(NN,IZ),NN=1,128), IZ=IZMIN,IZMAX)
cc61		WRITE (10,*) ((EB(NN,IZ),NN=1,128), IZ=IZMIN,IZMAX)
	CLOSE (UNIT=10)
	GO TO 100

C COMPARISON OF THEORETICAL AND MEASURED MASSES
C ONLY LINEPRINTER OUTPUT
 70	PRINT 57, KOPT
	M = 1
C MASSSTABSEINHEIT IN VIELFACHEN VON 0.1 MEV
	IZMAX = 144
	IF (KOPT.GE.4) IZMAX = 93
	DO 85 IZ=1,IZMAX
	NMIN = NPD(IZ)
	NNMAX = NND(IZ) - NMIN + 1
	IF (NNMAX.GT. 59) NNMAX = 59
C THE NEUTRON-RICH SIDE IS OMITTED

	DO 71 NN=1,NNMAX
	N = NMIN - 1 + NN
	IA = IZ + N
	IF (KOPT.EQ.5) CALL EBLYS(IZ,IA,EBX,EXCS,SHLL,2,2)
	IF (KOPT.EQ.6) CALL EBHILF(IZ,IA,EBX)
	EBLD(NN) = EBX
C KENNZEICHNUNG GROESSERER ABWEICHUNGEN
C ZWISCHEN EXPERIMENTELLEN UND THEORETISCHEN MASSEN
C IV =   , *,** FUER LT 1 MEV, LT 2 MEV, GT 2 MEV
	ABW(NN) = EB(NN,IZ) - EBX
	IF (EB(NN,IZ).LT.0.1) ABW(NN) = 0
	ABX = ABS(ABW(NN))
	IF(ABX.LT.1) THEN
		IV(NN) = BLANK
	ELSEIF(ABX.LT.2) THEN
		IV(NN) = BLANK // STAR
	ELSE
		IV(NN) = STAR // STAR
	ENDIF
71	CONTINUE

	IAMIN = IZ + NMIN
	PRINT 58, IZ,NMIN,IAMIN

	INMAX = (NNMAX+9)/10
	DO 72 IN=1,INMAX
	NN1 = (IN-1)*10 + 1
	NN2 = MIN(NN1+9,NNMAX)
	PRINT 74, (EBLD(NN),NN=NN1,NN2)
72	PRINT 73, (IV(NN),EB(NN,IZ),NN=NN1,NN2)
73	FORMAT ('      EXP ',5(A,F6.1),2X,5(A,F6.1)/)
74	FORMAT ('          ',5F8.1,2X,5F8.1)

C PLOT OF THE DEVIATIONS
	DO 795 NN=1,59
	N = NMIN - 1 + NN
	DO 75 IYY=1,45
75	PLOT(IYY,NN) = BLANK
	IY = (ABW(NN) + M*2.25)/(M*0.1)
	IY = IY + 1
	IF (IY.LT.23) GO TO 77
	IYMAX = IY
	IF (IYMAX.GT.45) IYMAX = 45
	DO 76 IYY=23,IYMAX
	PLOT(IYY,NN) = STAR
	IF (2*(N/2).EQ.N) PLOT(IYY,NN) = PLUS
76	CONTINUE
	GO TO 79
77	IYMIN = IY
	IF (IYMIN.LE.0) IYMIN = 1
	DO 78 IYY=IYMIN,23
	PLOT(IYY,NN) = STAR
	IF (2*(N/2).EQ.N) PLOT(IYY,NN) = PLUS
78	CONTINUE
79	IF (5*(N/5).EQ.N) PLOT(23,NN) = IK
795	CONTINUE

	DO 80 IYY=1,45
	IY = 46 - IYY
	ABX = (IY-23) * M*0.1
80	PRINT 81, ABX,(PLOT(IY,NN),NN=1,59),ABX
81	FORMAT (1X,F4.1,1X,59(1X,A),1X,F4.1)
85	PRINT 56

100	WRITE(6,*)'END'
        CONTINUE
	END

	SUBROUTINE EBLYS(IZ,IA,EB,EXCS,SHLL,KPAIRG,KSHELL)
C BINDING ENERGY OF THE NUCLEUS IZ,IA IN MEV
C MYERS-SWIATECKI MASS FORMULA (LYSEKIL, ARKIV FYSIK 36 )
C KPAIRG, KSHELL = KONTROLLZAHLEN, .NE.0 WENN EVEN-ODD-KORREKTUR
C BZW. SCHALENKORREKTUR
C FROM MYERS, TAKEN FROM BLANN'S ALICE, MODIFIED
C NEUTRONEN- UND PROTONENSCHALEN GETRENNT UND MODIFIZIERT
C PUEHLHOFER NOV. 75

	DIMENSION EM(10,2),EMP(10,2),XK(10,2),Y(2),F(2)

C KONSTANTEN
	PARAMETER (CAY1=1.15303,CAY2=0,CAY3=200)
	PARAMETER (CAY5=8.07144,CAY6=7.28899,GAMMA=1.7826,A1=15.4941)
	PARAMETER (A2=17.9439,A3=0.7053,D=0.444,C=5.8,SMALC=0.325)
	IF (KPAIRG.EQ.0) THEN
		CAY4 = 0
	ELSE
		CAY4=11
	ENDIF

C MAGISCHE SCHALEN
	DATA EM /0,2,8,14,28,50,82,126,184,258,
     1	0,2,8,14,28,50,82,114,164,258/
	DO 3 J=1,2
	DO 3 I=1,10
	EMP(I,J) = EM(I,J)**(5./3.)
3	CONTINUE
	DO 4 J=1,2
	DO 4 I=1,9
	XK(I,J) = 0.6*(EMP(I+1,J)-EMP(I,J))/(EM(I+1,J)-EM(I,J))
4	CONTINUE
	RZ=.863987/A3
	L=0

	N = IA - IZ
	Z = IZ
	UN = N
	A = IA

	A3RT=A**(1./3.)
	A2RT=SQRT(A)
	A3RT2=A3RT**2
	ZSQ=Z**2
	SYM=((UN-Z)/A)**2
	ACOR=1-GAMMA*SYM
	PARMAS=CAY5*UN+CAY6*Z
	VOLNUC=-A1*ACOR*A
	SUFNUC=A2*ACOR*A3RT2
	COULMB=A3*ZSQ/A3RT
	FUZSUR=-CAY1*ZSQ/A
	ODDEV=-(1+2*(N/2)-UN+2*(IZ/2)-Z)/A2RT*CAY4
	WTERM = 0
	WOTNUC=COULMB+FUZSUR+ODDEV+WTERM
	SMASS=WOTNUC+VOLNUC+SUFNUC

C SCHALENKORREKTUR
	SHLL = 0
	QCALC = 0
	THETA = 0
	IF (KSHELL.EQ.0) GO TO 31
	C2=(SUFNUC+WTERM)/A3RT2
	X=COULMB/(2*(SUFNUC+WTERM))
17	BARR=0
18	Y(1)=UN
	Y(2)=Z
	DO 22 J=1,2
	DO 19 I=1,9
	IF (Y(J)-EM(I+1,J)) 21,21,19
19	CONTINUE
20	GO TO 100
21	F(J) = XK(I,J)*(Y(J)-EM(I,J))-.6*(Y(J)**(5./3.)-EMP(I,J))
22	CONTINUE
	S=(2/A)**(2./3.)*(F(1)+F(2))-SMALC*A3RT
	EE=2*C2*D**2*(1-X)
	FF=.42591771*C2*D**3*(1+2*X)/A3RT
	SSHELL=C*S
	V=SSHELL/EE
	EPS=1.5*FF/EE
	IF(EE*(1-3*V).LE.0) GO TO 23
	QCALC=0
	THETA=0
	SHLL=SSHELL
	GO TO 31
23	TO=1
24	DO 25 IPQ=1,10
	T=TO-(1-EPS*TO-V*(3-2*TO**2)*EXP(-TO**2))/(-EPS+V*(10*TO-4
     1 *TO**3)*EXP(-TO**2))
	IF (T.LE.0 .OR. T.GT.6) GO TO 27
	IF (ABS(T-TO) .LT.1E-4) GO TO 26
	TO=T
25	CONTINUE
	GO TO 27
26	IF (2*EE*(1-2*EPS*T-V*(3-12*T**2+4*T**4)*EXP(-T**2))
     1 .GT.0) GO TO 30
27	DO 28 I=1,20
	TO=REAL(I)/10
	GL=EE*(1-EPS*TO-V*(3-2*TO**2)*EXP(-TO**2))
	IF (GL.GE.0) GO TO 24
28	CONTINUE
	GO TO 31
30	THETA=T
	ALPHA0=D*SQRT(5.)/A3RT
	ALPHA=ALPHA0*THETA
	SIGMA=ALPHA*(1+ALPHA/14)
	QCALC=.004*Z*(RZ*A3RT)**2*(EXP(2*SIGMA)-EXP(-SIGMA))
	SHLL=EE*T**2-FF*T**3+SSHELL*(1-2*T**2)*EXP(-T**2)
31	CMASS=SMASS+SHLL

	EB = - CMASS
	EXCS = PARMAS - EB
100	RETURN
	END

	SUBROUTINE EBHILF(IZ,IA,EBX)
C BINDING ENERGY EBX
C DROPLET MODEL MASS FORMULA OF HILF ET AL. NUCL.PHYS. A203(1973)627

	COMMON /ENERGY/ SPA,ETH,ZA,ZB,QTH,ESHTH,DEL,EPS
	COMMON /EBSCBK/ ISHELL,EBIN

	XZ = IZ
	XA = IA
	X = AMASMS(XZ,XA)
	EBX = EBIN
	RETURN
	END

	FUNCTION AMASMS(XZ,XA)
	COMMON /TKZZ/ ZBO
	COMMON /KOEF/ RN,ALP,BET,GAM,CSA,COJ,COQ,COK,COL,COM,CD,SAA,   
     1  SAB,SAC,AWI,CONE
	COMMON /ENERGY/ SPA,ETH,ZA,ZB,QTH,ESHTH,DEL,EPS
	COMMON /PARA/ A,AWDD,AWDR,ASS,AT,DB,DC,DS,SUR,CUR,CUL,AB,ABW,
     1  D,E,ECE,ECZ,ECD,ECV,ECF,SHALFU
	COMMON /EBSCBK/ ISHELL,EBIN
	LOGICAL FAIL,FIRST
	DATA FIRST/.TRUE./
	EBIN = 0
	XN=XA-XZ
	IF (.NOT.FIRST) GO TO 10
	RN=1.18229
	ALP=16.1495
	BET=21.573
	GAM=10.143
	CSA=12.548
	COJ=38.7176
	COQ=16.337
	COL=120
	COM=5
	COK=300
	CD=1.47147
	SAA=.558
	SAB=5.0725
	SAC=.2386
	AWI=30
	CONE=.6*1.43982/RN
	CTWO=CONE**2/84*(.25/COJ+4.5/COK)
	CTHR=CD/(RN**3)
	CFOU=.75*(1.5/3.1415926536)**(2./3.)*1.43982/RN
	CFIV=CONE/64*CONE/COQ
	FIRST=.FALSE.
	SHELZ=0
	SHELN=0
10	IF (ISHELL.EQ.1) GOTO 11
	CALL COSWI(XZ,XN,SHELZ,SHELN,FAIL)
	IF (FAIL) RETURN
11	CONTINUE
	A=XA
	ZBO=XZ
	AWDR = A**(1./3.)
	AWDD = AWDR*AWDR
	ASS = (XN-XZ)/A
	SHALFU=0
	IF (ISHELL.EQ.1) GOTO 12
	SHFZN = (SHELZ+SHELN)*2**(2./3.)/AWDD
	SHALFU = SAB*(SHFZN-SAC*AWDR)
12	CONTINUE
	AT = (AWDR/SAA)**2
	XZZ=XZ*XZ
	ECE=CONE*XZZ/AWDR
	ECZ=CTWO*XZZ*AWDR
	ECD=CTHR*XZZ/A
	ECV=CFOU*XZ**(4./3.)/AWDR
	ECF=CFIV*XZZ
	DB = 2.25*COJ/COQ
	DS = DB*COJ
	DB = DB/AWDR
	DC = 3./16.*CONE/COQ*XZ/AWDD
	CALL JMIN(ZA,EMIN,FAIL)
	IF (FAIL) RETURN
	DEL=D
	EPS = E
	SPA = .5*ECE/((BET+DS*D*D)*AWDD+GAM*AWDR)
	EPAIR = 11*(MOD(XZ,2.)+MOD(XN,2.)-1)/SQRT(A)
	EWI = AWI*ABS(ASS)
	EO = 8.07144*XN+7.28899*XZ
	ESHTH=SHALFU*ABW
	ETH=EMIN-ALP*A-CSA*AWDR-ECZ-ECD-ECV-ECF+EPAIR+EWI+EO
	EBIN=-(ETH-EO)
	ZB = 1/SQRT(ZA)
	QTH = .004*XZ*RN*RN*AWDD*(ZA*ZA-1/ZA)
	AMASDP=ETH
	AMASMS=AMASDP
	RETURN
	END

	SUBROUTINE JMIN(ZMIN,EMIN,FAIL)
	COMMON /TKZZ/ ZBO
	COMMON /EBSCBK/ ISHELL,EBIN
	COMMON /KOEF/ RN,ALP,BET,GAM,CSA,COJ,COQ,COK,COL,COM,CD,SAA,   
     1  SAB,SAC,AWI,CONE
	COMMON /PARA/ A,AWDD,AWDR,ASS,AT,DB,DC,DS,SUR,CUR,CUL,AB,ABW,
     1  DEL,EPS,ECE,ECZ,ECD,ECV,ECF,SHALFU
	COMMON/ITT/NOMIN
	DIMENSION ZG(15),SURG(15),CURG(15),CULG(15),ABWG(15)
	LOGICAL FAIL
	DATA ZG / 1.02, 1.04, 1.06, 1.08, 1.10, 1.12, 1.14, 1.16, 1.18,
     1	1.20, 1.22, 1.24, 1.26, 1.28, 1.30/
	DATA SURG /
     1 1.0001561203,1.0006095939,1.0013394307,1.0023262948,1.0035523524,
     1 1.0050011362,1.0066574243,1.0085071305,1.0105372067,1.0127355548,
     1 1.0150909463,1.0175929513,1.0202318727,1.0229986873,1.0258849925/
	DATA CURG /
     1 1.0001575994,1.0006210852,1.0013771113,1.0024131099,1.0037172329,
     1 1.0052782987,1.0070857439,1.0091295792,1.0114003494,1.0138890969,
     1 1.0165873282,1.0194869832,1.0225804070,1.0258603242,1.0293198150/
	DATA CULG /
     1 0.9999215027,0.9996918573,0.9993194760,0.9988123174,0.9981779124,
     1 0.9974233892,0.9965554961,0.9955806237,0.9945048245,0.9933338325,
     1 0.9920730808,0.9907277183,0.9893026256,0.9878024300,0.9862315190/
	DATA ABWG /
     1 0.782015E-04,0.3058454E-03,0.6729948E-03,0.11703476E-02,0.1789193
     1 E-02,
     1 0.25213721E-02,0.33592399E-02,0.42956317E-02,0.53238307E-02,
     1 0.64375389E-02,0.76308488E-02,0.88982186E-02,0.102344483E-01 ,
     1 0.116346572E-01,0.130942639E-01/
	NOMIN=0
	ZMIN = 1
	EMIN=ERG(ZMIN)
	IF (ISHELL .GE.1) RETURN
	IF(SHALFU.LE.0) RETURN
	EO=EMIN
	EMIN=0
	DO 1 I=1,15
	DEL=(ASS+DC)/(1+DB*SURG(I))
	DDEL=DEL*DEL
	EPS=(-2*BET/AWDR*SURG(I)+COL*DDEL+ECE/A*CULG(I))/COK
	AB=AT*ABWG(I)
	SHELL=SHALFU*(1-AB-AB)*EXP(-AB)
	ETEST=(COJ*DDEL-.5*COK*EPS*EPS+.5*COM*DDEL*DDEL)*A+
     1  (BET+DS*DDEL)*AWDD*SURG(I)+GAM*CURG(I)*AWDR+ECE*CULG(I)+SHELL-EO
	IF(I.NE.1) GO TO 3
	IF(ETEST.LT.EMIN) GO TO 5
	EM=ERG(0.98)-EO
	GO TO 2
3	IF(EMIN.LT.ETEST) GO TO 2
5	EM=EMIN
	EMIN=ETEST
	ZMIN=ZG(I)
1	CONTINUE

4	NOMIN=1
	ZMIN=1
	EMIN=EO
	FAIL=.FALSE.
	RETURN
2	A2=EM+ETEST-EMIN-EMIN
	A1=.5*(EM-ETEST)
	IF(A2.EQ.0.) GO TO 4
	ZMIN=ZMIN+0.02*A1/A2
	EMIN=ERG(ZMIN)
	FAIL=.FALSE.
	RETURN
	END

	FUNCTION ERG(Z)
	COMMON /KOEF/ RN,ALP,BET,GAM,CSA,COJ,COQ,COK,COL,COM,CD,SAA,   
     1  SAB,SAC,AWI,CONE
	COMMON /PARA/ A,AWDD,AWDR,ASS,AT,DB,DC,DS,SUR,CUR,CUL,AB,ABW,
     1  DEL,EPS,ECE,ECZ,ECD,ECV,ECF,SHALFU
	EPS = 1/Z**3
	IF(ABS(Z-1).LT.1E-6) GO TO 1
	IF (Z-1) 2,1,3
1	SUR=1
	CUR=1
	CUL=1
	ABW=1
	AB=0
	GO TO 4
2	EPS = 1/EPS
3	EPS = SQRT(1-EPS)
	XXX = 1 - EPS*EPS
	XX = SQRT(XXX)
	X = XXX**(1./3.)
	SUR = .5*(1 +ASIN(EPS)/(EPS*XX))*X
	CUL = .5/EPS*LOG((1+EPS)/(1-EPS))*X
	CUR = .5*(1/X+CUL*X)
	AB = AT*(1 + CUL - 2/EPS*ATAN(EPS/XX)*SQRT(X))
	ABW = (1-2*AB)*EXP(-AB)
4	DEL = (ASS+DC)/(1+DB*SUR)
	DDEL = DEL*DEL
	SHELL=SHALFU*ABW
	EPS = (-2*BET/AWDR*SUR+COL*DDEL+ECE/A*CUL)/COK
	ERG=(COJ*DDEL-.5*COK*EPS*EPS+.5*COM*DDEL*DDEL)*A+(BET+DS*DDEL)*
     1	AWDD*SUR+GAM*CUR*AWDR+ECE*CUL+SHELL
	RETURN
	END

	SUBROUTINE COSWI(XZ,XN,SHELZ,SHELN,FAIL)
	LOGICAL FAIL
	DIMENSION ZMAG(2,8)
	DATA ZMAG/2,2,8,8,14,14,28,28,50,50,82,82,
     1	114,126,164,184/
	EE = 2./3.
	E = EE+1
	IX=XZ+0.01
	X=IX
	K = 1
20	IF(IX-NINT(ZMAG(K,1))) 2,1,10
1	SHELL = 0
	GO TO (21,22), K
2	IF(IX) 14,1,3
3	SHELL = .6*X*(ZMAG(K,1)**EE-X**EE)
	GO TO (21,22), K
10	I = 2
11	IF(IX-NINT(ZMAG(K,I))) 13,1,12
12	I = I+1
	IF(I-9) 11,14,14
13	SHELL = .6*((ZMAG(K,I)**E-ZMAG(K,I-1)**E)*(X-ZMAG(K,I-1))/
     1	(ZMAG(K,I)-ZMAG(K,I-1))- X**E+ZMAG(K,I-1)**E)
	GO TO (21,22), K
21	SHELZ = SHELL
	IX=XN+0.01
	X=IX
	K = 2
	GO TO 20
22	SHELN =SHELL
	FAIL=.FALSE.
	RETURN
14	CONTINUE
	FAIL=.TRUE.
	RETURN
	END

	FUNCTION NPDRIP(IZ)
C NEUTRON NUMBER FOR THE PROTON DRIP LINE (EB = -3 MEV)
C ANALYTIC APPROXIMATION TO MYERS-SWIATECKI UCRL

	PARAMETER (ALPHA = -5, 	BETA = 0.70, GAMMA = 4.95E-3)
	NPDRIP = MAX( NINT(ALPHA + BETA*IZ + GAMMA*IZ*IZ), 0 )

	END

	FUNCTION NNDRIP(IZ)
C NEUTRON NUMBER FOR THE NEUTRON DRIP LINE
C ANALYT. NAEHERUNGSFORMEL FUER MYERS-SWIATECKI UCRL

	PARAMETER (ALPHA = 5, BETA = 2.18, GAMMA = 0)
	NNDRIP = NINT(ALPHA + BETA*IZ + GAMMA*IZ*IZ)

	END

