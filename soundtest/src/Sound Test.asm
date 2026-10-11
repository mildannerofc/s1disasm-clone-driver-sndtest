; ===========================================================================
; Sound Test - Knuckles Chaotix-inspired monitor for Sonic 1 AS + Clone Driver
; ---------------------------------------------------------------------------
; Uses the existing SMPS driver RAM to display the live FM/PSG note state.
; It does not replace the YM2612/SN76489 driver; it only reads its track state.
; ===========================================================================

GM_SoundTest:
		; Fade the previous screen to black before changing VDP state.
		jsr	(PaletteFadeOut).l
		move.b	#bgm_Stop,d0
		jsr	(QueueSound2).l
		jsr	(ClearPLC).l
		disable_ints
		disable_display

		lea	(vdp_control_port).l,a6
		move.w	#$8004,(a6)			; 40-cell display, normal mode
		move.w	#$8200+(vram_fg>>10),(a6)
		move.w	#$8400+(vram_bg>>13),(a6)
		move.w	#$9001,(a6)			; 64-cell H-scroll table
		move.w	#$8700|$00,(a6)			; palette line 1, colour 0 = dark maroon
		move.w	#$8B00,(a6)			; full-screen vertical scrolling
		move.w	#$8F02,(a6)			; 2-byte VRAM auto-increment
		clr.b	(f_wtr_state).w
		jsr	(ClearScreen).l

		; Clear the sprite attribute buffer as well.
		; The Sound Test uses no sprites, so this prevents sprites left by the
		; previous game mode from appearing when the screen is opened.
		lea	(v_spritetablebuffer).w,a1
		moveq	#0,d0
		move.w	#($280/4)-1,d7
.clear_sprite_buffer:
		move.l	d0,(a1)+
		dbf	d7,.clear_sprite_buffer

		; Load the Sound Test palette into the fade target buffer only.
		; Do not call PalLoad here: that writes the target colours straight into
		; v_palette and can expose them before the fade-in has begun.
		clearRAM	v_palette,v_palette_end
		clearRAM	v_palette_fading,v_palette_fading_end
		moveq	#palid_SoundTest,d0
		jsr	(PalLoad_Fade).l

		; Nemesis-compressed 8x16 reference font + helper symbols + icons.
		locVRAM	SoundTest_ArtTile*tile_size
		lea	(SoundTest_Art_Nem).l,a0
		jsr	(NemDec).l

		; Upload the real 40x28 foreground tilemap first.
		lea	(SoundTest_Tilemap).l,a1
		locVRAM	vram_fg,d0
		moveq	#39,d1
		moveq	#27,d2
		jsr	(TilemapToVRAM).l

		bsr.w	SoundTest_DrawStatic
		bsr.w	SoundTest_SelectInitialEntry
		bsr.w	SoundTest_DrawSelection
		clr.b	(v_soundtest_timer).w
		bsr.w	SoundTest_UpdateChannels

		; Transfer one all-black palette to CRAM before showing the new screen.
		; The display is still disabled, so no colours from the previous mode
		; can flash for a frame when the Sound Test becomes visible.
		move.b	#id_VBlank_PaletteFade,(v_vblank_routine).w
		jsr	(WaitForVBlank).l		; also re-enables interrupts
		move.b	#id_VBlank_SoundTest,(v_vblank_routine).w
		enable_display
		jsr	(PaletteFadeIn).l

SoundTest_Loop:
		; CORREÇÃO DA TELA PRETA: Se sua engine travar aqui, certifique-se de usar um ID padrão 
		; como #2 (id_VBlank_Title) para manter as interrupções estáveis.
		move.b	#id_VBlank_SoundTest,(v_vblank_routine).w
		jsr	(WaitForVBlank).l
		bsr.w	SoundTest_Controls
		cmpi.b	#id_SoundTest,(v_gamemode).w
		bne.s	SoundTest_Return

		subq.b	#1,(v_soundtest_timer).w
		bpl.s	SoundTest_Loop
		move.b	#3,(v_soundtest_timer).w
		bsr.w	SoundTest_UpdateChannels
		bra.s	SoundTest_Loop

SoundTest_Return:
		rts

; ---------------------------------------------------------------------------
; Controller handling (CORRIGIDO: Debounce via v_jpadpress1 e Setas Nativas)
; ---------------------------------------------------------------------------
SoundTest_Controls:
		move.b	(v_jpadpress1).w,d0	; Lê unicamente o pulso do botão apertado no frame
		bne.s	.has_press
		rts

.has_press:
		btst	#bitStart,d0
		bne.w	SoundTest_Exit

		btst	#bitA,d0
		bne.s	.add16
		btst	#bitB,d0
		bne.s	.sub16
		btst	#bitL,d0			; CORRIGIDO: Constante padrão Esquerda
		bne.s	.prev
		btst	#bitR,d0			; CORRIGIDO: Constante padrão Direita
		bne.s	.next
		btst	#bitC,d0
		bne.s	.replay
		rts

.add16:
		move.w	(v_soundtest_selection).w,d1
		addi.w	#SoundTest_SelectionStride,d1
		bra.s	.store

.sub16:
		move.w	(v_soundtest_selection).w,d1
		subi.w	#SoundTest_SelectionStride,d1
		bpl.s	.store
		addi.w	#SoundTest_SelectionCount,d1
		bra.s	.store

.prev:
		move.w	(v_soundtest_selection).w,d1
		subq.w	#1,d1
		bpl.s	.store
		move.w	#SoundTest_SelectionLast,d1
		bra.s	.store

.next:
		move.w	(v_soundtest_selection).w,d1
		addq.w	#1,d1
		cmpi.w	#SoundTest_SelectionCount,d1
		blo.s	.store
		clr.w	d1
		bra.s	.store

.replay:
		bsr.w	SoundTest_PlaySelected
		move.b	#0,(v_soundtest_timer).w
		bsr.w	SoundTest_UpdateChannels
		rts

.store:
		cmpi.w	#SoundTest_SelectionCount,d1
		blo.s	.storeok
		subi.w	#SoundTest_SelectionCount,d1
.storeok:
		move.w	d1,(v_soundtest_selection).w
		bsr.w	SoundTest_DrawSelection
		bsr.w	SoundTest_UpdateChannels
		rts

SoundTest_Exit:
		jsr	(PaletteFadeOut).l
		move.b	#bgm_Stop,d0
		jsr	(QueueSound2).l
		move.b	#SoundTest_ReturnMode,(v_gamemode).w
		rts

; ---------------------------------------------------------------------------
; Start screen and music title.
; ---------------------------------------------------------------------------
SoundTest_DrawStatic:
		move.w	#Tile_Pal1|Tile_Prio,d2

		lea	SoundTest_Title(pc),a0
		moveq	#SoundTest_TitleX,d0
		moveq	#SoundTest_TitleY,d1
		bsr.w	SoundTest_DrawText

		lea	SoundTest_MusicLabel(pc),a0
		moveq	#SoundTest_MusicLabelX,d0
		moveq	#SoundTest_MusicLabelY,d1
		bsr.w	SoundTest_DrawText

		lea	SoundTest_Help(pc),a0
		moveq	#SoundTest_HelpX,d0
		moveq	#SoundTest_HelpY,d1
		bsr.w	SoundTest_DrawText
		lea	SoundTest_StartMenu(pc),a0
		moveq	#SoundTest_StartMenuX,d0
		moveq	#SoundTest_StartMenuY,d1
		bsr.w	SoundTest_DrawText

		lea	SoundTest_ChannelFM1(pc),a0
		moveq	#SoundTest_ChannelX,d0
		moveq	#SoundTest_FM1Y,d1
		bsr.w	SoundTest_DrawText
		lea	SoundTest_ChannelFM2(pc),a0
		moveq	#SoundTest_ChannelX,d0
		moveq	#SoundTest_FM2Y,d1
		bsr.w	SoundTest_DrawText
		lea	SoundTest_ChannelFM3(pc),a0
		moveq	#SoundTest_ChannelX,d0
		moveq	#SoundTest_FM3Y,d1
		bsr.w	SoundTest_DrawText
		lea	SoundTest_ChannelFM4(pc),a0
		moveq	#SoundTest_ChannelX,d0
		moveq	#SoundTest_FM4Y,d1
		bsr.w	SoundTest_DrawText
		lea	SoundTest_ChannelFM5(pc),a0
		moveq	#SoundTest_ChannelX,d0
		moveq	#SoundTest_FM5Y,d1
		bsr.w	SoundTest_DrawText
		lea	SoundTest_ChannelFM6(pc),a0
		moveq	#SoundTest_ChannelX,d0
		moveq	#SoundTest_FM6Y,d1
		bsr.w	SoundTest_DrawText
		lea	SoundTest_ChannelPSG1(pc),a0
		moveq	#SoundTest_ChannelX,d0
		moveq	#SoundTest_PSG1Y,d1
		bsr.w	SoundTest_DrawText
		lea	SoundTest_ChannelPSG2(pc),a0
		moveq	#SoundTest_ChannelX,d0
		moveq	#SoundTest_PSG2Y,d1
		bsr.w	SoundTest_DrawText
		lea	SoundTest_ChannelNoise(pc),a0
		moveq	#SoundTest_ChannelX,d0
		moveq	#SoundTest_NoiseY,d1
		bsr.w	SoundTest_DrawText

		rts

SoundTest_DrawMusic:
		bra.w	SoundTest_DrawSelection

; ---------------------------------------------------------------------------
; Select initial index entry
; ---------------------------------------------------------------------------
SoundTest_SelectInitialEntry:
        moveq   #0,d0
        move.b  #SoundTest_InitialID,d0
        lea     SoundTest_SelectionTable(pc),a0
        moveq   #SoundTest_SelectionCount-1,d1
        moveq   #0,d2
.find:
        cmp.b   (a0),d0
        beq.s   .found
        adda.w  #SoundTest_EntryRecordSize,a0
        addq.w  #1,d2
        dbf     d1,.find
        clr.w   d2
.found:
        move.w  d2,(v_soundtest_selection).w
        rts

SoundTest_DrawSelection:
		move.w	#Tile_Pal1|Tile_Prio,d2
		lea	SoundTest_BlankSelectionHeader(pc),a0
		moveq	#SoundTest_MusicLabelX,d0
		moveq	#SoundTest_MusicLabelY,d1
		bsr.w	SoundTest_DrawText
		lea	SoundTest_BlankMusic(pc),a0
		moveq	#SoundTest_MusicNameX,d0
		moveq	#SoundTest_MusicLabelY,d1
		bsr.w	SoundTest_DrawText

		move.w	(v_soundtest_selection).w,d6
		lsl.w	#3,d6
		lea	SoundTest_SelectionTable(pc),a1
		moveq	#0,d4
		move.b	(a1,d6.w),d4
		moveq	#0,d5
		move.b	1(a1,d6.w),d5
		movea.l	4(a1,d6.w),a2

		tst.b	d5
		beq.s	.music_type
		lea	SoundTest_SFXLabel(pc),a0
		bra.s	.draw_type
.music_type:
		lea	SoundTest_MusicLabel(pc),a0
.draw_type:
		moveq	#SoundTest_MusicLabelX,d0
		moveq	#SoundTest_MusicLabelY,d1
		move.w	#Tile_Pal1|Tile_Prio,d2
		bsr.w	SoundTest_DrawText

		move.w	d4,d1
		bsr.w	SoundTest_FormatByteHex
		moveq	#SoundTest_MusicID_X,d0
		moveq	#SoundTest_MusicLabelY,d1
		move.w	#Tile_Pal1|Tile_Prio,d2
		lea	(v_soundtest_textbuf).w,a0
		bsr.w	SoundTest_DrawText

		movea.l	a2,a0
		moveq	#SoundTest_MusicNameX,d0
		moveq	#SoundTest_MusicLabelY,d1
		move.w	#Tile_Pal1|Tile_Prio,d2
		bsr.w	SoundTest_DrawText
		rts

SoundTest_PlaySelected:
		move.w	(v_soundtest_selection).w,d6
		cmpi.w	#SoundTest_SelectionCount,d6
		blo.s	.valid
		clr.w	d6
		move.w	d6,(v_soundtest_selection).w
.valid:
		lsl.w	#3,d6
		lea	SoundTest_SelectionTable(pc),a0
		moveq	#0,d0
		move.b	(a0,d6.w),d0
		jsr	(QueueSound2).l
		rts

; ---------------------------------------------------------------------------
; Channel display tracking
; ---------------------------------------------------------------------------
SoundTest_UpdateChannels:
		lea	(Clone_Driver_RAM).w,a6

		lea	SMPS_RAM.v_music_fm1_track(a6),a0
		moveq	#8,d0
		bsr.w	SoundTest_DrawFMTrack
		lea	SMPS_RAM.v_music_fm2_track(a6),a0
		moveq	#10,d0
		bsr.w	SoundTest_DrawFMTrack
		lea	SMPS_RAM.v_music_fm3_track(a6),a0
		moveq	#12,d0
		bsr.w	SoundTest_DrawFMTrack
		lea	SMPS_RAM.v_music_fm4_track(a6),a0
		moveq	#14,d0
		bsr.w	SoundTest_DrawFMTrack
		lea	SMPS_RAM.v_music_fm5_track(a6),a0
		moveq	#16,d0
		bsr.w	SoundTest_DrawFMTrack

		lea	SMPS_RAM.v_music_dac_track(a6),a0
		; DAC uses bit 7 for track-playing. Clone Driver does not use bit 1
		; (the DAC "track at rest" test is explicitly commented out in its driver).
		btst	#7,SMPS_Track.PlaybackControl(a0)
		beq.s	.fm6slot
		bsr.w	SoundTest_DrawDACSlot
		bra.s	.psg1
.fm6slot:
		lea	SMPS_RAM.v_music_fm6_track(a6),a0
		bsr.w	SoundTest_DrawFM6Slot

.psg1:
		lea	SMPS_RAM.v_music_psg1_track(a6),a0
		moveq	#20,d0
		bsr.w	SoundTest_DrawPSGTrack
		lea	SMPS_RAM.v_music_psg2_track(a6),a0
		moveq	#22,d0
		bsr.w	SoundTest_DrawPSGTrack
		bsr.w	SoundTest_DrawNoise
		rts

SoundTest_DrawFMTrack:
		move.w	d0,d5
		move.w	SMPS_Track.Freq(a0),d1
		btst	#7,SMPS_Track.PlaybackControl(a0)
		beq.w	SoundTest_DrawRest
		btst	#1,SMPS_Track.PlaybackControl(a0)
		bne.w	SoundTest_DrawRest
		tst.w	d1
		beq.w	SoundTest_DrawRest
		movea.l	a0,a2
		lea	(FMFrequencies).l,a1
		moveq	#0,d2
		moveq	#SoundTest_FMFrequencyCount-1,d3
.fmfind:
		cmp.w	(a1)+,d1
		beq.s	.fmfound
		addq.w	#1,d2
		dbf	d3,.fmfind
		movea.l	a2,a0
		move.w	d5,d0
		bra.w	SoundTest_DrawRest
.fmfound:
		move.w	d2,d1
		bsr.w	SoundTest_FormatFMNote
		move.w	d5,d1
		move.w	#Tile_Pal1|Tile_Prio,d2
		moveq	#SoundTest_NoteX,d0
		lea	(v_soundtest_textbuf).w,a0
		bsr.w	SoundTest_DrawText
		if SoundTest_ShowFrequency
		move.w	SMPS_Track.Freq(a2),d1
		bsr.w	SoundTest_FormatFrequency
		move.w	d5,d1
		move.w	#Tile_Pal1|Tile_Prio,d2
		moveq	#SoundTest_FreqX,d0
		lea	(v_soundtest_textbuf).w,a0
		bsr.w	SoundTest_DrawText
		endif
		rts

SoundTest_DrawFM6Slot:
		move.l	a0,-(sp)
		move.w	#SoundTest_FM6Y,-(sp)
		lea	SoundTest_DACNameBlank(pc),a0
		moveq	#SoundTest_DACNameX,d0
		move.w	(sp),d1
		move.w	#Tile_Pal1|Tile_Prio,d2
		bsr.w	SoundTest_DrawText
		; Clear the DAC sample-rate column when FM6 takes this row back.
		lea	SoundTest_DACRateBlank(pc),a0
		moveq	#SoundTest_DACRateX,d0
		move.w	(sp),d1
		move.w	#Tile_Pal1|Tile_Prio,d2
		bsr.w	SoundTest_DrawText

		moveq	#SoundTest_ChannelX,d0
		moveq	#SoundTest_FM6Y,d1
		move.w	#Tile_Pal1|Tile_Prio,d2
		lea	SoundTest_ChannelFM6(pc),a0
		bsr.w	SoundTest_DrawText
		move.w	(sp)+,d0
		movea.l	(sp)+,a0
		moveq	#SoundTest_FM6Y,d0
		bra.w	SoundTest_DrawFMTrack

SoundTest_DrawDACSlot:
		; DAC occupies the FM6 row. The Clone Driver uses bit 7 to mark an
		; active track; bit 1 is not used for DAC (see the driver's commented code).
		moveq	#SoundTest_FM6Y,d5
		moveq	#SoundTest_ChannelX,d0
		moveq	#SoundTest_FM6Y,d1
		move.w	#Tile_Pal1|Tile_Prio,d2
		lea	SoundTest_ChannelDAC(pc),a0
		bsr.w	SoundTest_DrawText

		; Clear all DAC columns before reading the live track state.
		lea	SoundTest_DACNameBlank(pc),a0
		move.w	d5,d1
		moveq	#SoundTest_DACNameX,d0
		move.w	#Tile_Pal1|Tile_Prio,d2
		bsr.w	SoundTest_DrawText
		lea	SoundTest_BlankFreq(pc),a0
		move.w	d5,d1
		moveq	#SoundTest_FreqX,d0
		move.w	#Tile_Pal1|Tile_Prio,d2
		bsr.w	SoundTest_DrawText
		lea	SoundTest_DACRateBlank(pc),a0
		move.w	d5,d1
		moveq	#SoundTest_DACRateX,d0
		move.w	#Tile_Pal1|Tile_Prio,d2
		bsr.w	SoundTest_DrawText

		lea	(Clone_Driver_RAM).w,a6
		lea	SMPS_RAM.v_music_dac_track(a6),a0
		btst	#7,SMPS_Track.PlaybackControl(a0)
		beq.w	.dac_inactive

		; SavedDAC contains the active MegaPCM sample ID ($81-$E0).
		; $80 is the Clone Driver's no-sample/rest marker.
		moveq	#0,d4
		move.b	SMPS_Track.SavedDAC(a0),d4
		cmpi.b	#$80,d4
		beq.w	.dac_inactive
		bsr.w	SoundTest_LookupDACSample
		move.w	d1,d6			; preserve looked-up sample rate

		; Draw the sample name (known IDs, or UNUSED/UNKNOWN fallback).
		move.w	d5,d1
		moveq	#SoundTest_DACNameX,d0
		move.w	#Tile_Pal1|Tile_Prio,d2
		bsr.w	SoundTest_DrawText

		if SoundTest_ShowDACSampleRate
		tst.w	d6
		beq.s	.dac_done		; UNUSED/UNKNOWN entries have no rate
		move.w	d6,d1
		bsr.w	SoundTest_FormatDACRate
		move.w	d5,d1
		moveq	#SoundTest_DACRateX,d0
		move.w	#Tile_Pal1|Tile_Prio,d2
		lea	(v_soundtest_textbuf).w,a0
		bsr.w	SoundTest_DrawText
		endif
.dac_done:
		rts

.dac_inactive:
		; Retain the original rest marker and make sure the rate field is blank.
		move.w	d5,d0
		bsr.w	SoundTest_DrawRest
		lea	SoundTest_DACRateBlank(pc),a0
		move.w	d5,d1
		moveq	#SoundTest_DACRateX,d0
		move.w	#Tile_Pal1|Tile_Prio,d2
		bsr.w	SoundTest_DrawText
		rts

SoundTest_DrawPSGTrack:
		move.w	d0,d5
		move.w	SMPS_Track.Freq(a0),d1
		btst	#7,SMPS_Track.PlaybackControl(a0)
		beq.w	SoundTest_DrawRest
		btst	#1,SMPS_Track.PlaybackControl(a0)
		bne.w	SoundTest_DrawRest
		cmpi.w	#-1,d1
		beq.w	SoundTest_DrawRest
		movea.l	a0,a2
		bsr.w	SoundTest_PSGFreqToIndex
		tst.w	d1
		bpl.s	.psgfound
		movea.l	a2,a0
		move.w	d5,d0
		bra.w	SoundTest_DrawRest
.psgfound:
		bsr.w	SoundTest_FormatPSGNote
		move.w	d5,d1
		move.w	#Tile_Pal1|Tile_Prio,d2
		moveq	#SoundTest_NoteX,d0
		lea	(v_soundtest_textbuf).w,a0
		bsr.w	SoundTest_DrawText
		if SoundTest_ShowFrequency
		move.w	SMPS_Track.Freq(a2),d1
		bsr.w	SoundTest_FormatFrequency
		move.w	d5,d1
		move.w	#Tile_Pal1|Tile_Prio,d2
		moveq	#SoundTest_FreqX,d0
		lea	(v_soundtest_textbuf).w,a0
		bsr.w	SoundTest_DrawText
		endif
		rts

SoundTest_DrawNoise:
		lea	(Clone_Driver_RAM).w,a6
		lea	SMPS_RAM.v_music_psg3_track(a6),a0
		moveq	#24,d5
		btst	#7,SMPS_Track.PlaybackControl(a0)
		beq.w	SoundTest_DrawRestAtRow
		btst	#1,SMPS_Track.PlaybackControl(a0)
		bne.w	SoundTest_DrawRestAtRow
		cmpi.b	#$E0,SMPS_Track.VoiceControl(a0)
		bne.w	SoundTest_DrawRestAtRow

		move.b	SMPS_Track.PSGNoise(a0),d1
		bsr.w	SoundTest_FormatNoiseNote
		move.w	d5,d1
		move.w	#Tile_Pal1|Tile_Prio,d2
		moveq	#SoundTest_NoteX,d0
		lea	(v_soundtest_textbuf).w,a0
		bsr.w	SoundTest_DrawText

		lea	(Clone_Driver_RAM).w,a6
		lea	SMPS_RAM.v_music_psg3_track(a6),a0
		moveq	#0,d1
		move.b	SMPS_Track.PSGNoise(a0),d1
		bsr.w	SoundTest_FormatNoiseFrequency
		move.w	d5,d1
		move.w	#Tile_Pal1|Tile_Prio,d2
		moveq	#SoundTest_FreqX,d0
		lea	(v_soundtest_textbuf).w,a0
		bsr.w	SoundTest_DrawText
		rts

SoundTest_DrawRestAtRow:
		move.w	d5,d0
		bra.w	SoundTest_DrawRest

SoundTest_DrawRest:
		move.w	d0,d1
		move.w	#Tile_Pal1|Tile_Prio,d2
		moveq	#SoundTest_NoteX,d0
		lea	SoundTest_Rest(pc),a0
		bsr.w	SoundTest_DrawText
		lea	SoundTest_BlankFreq(pc),a0
		moveq	#SoundTest_FreqX,d0
		bsr.w	SoundTest_DrawText
		rts

; ---------------------------------------------------------------------------
; Format and conversion text utilities
; ---------------------------------------------------------------------------
SoundTest_NoteSemitoneAdjust: equ -1

SoundTest_FormatFMNote:
		moveq	#0,d0
		move.w	d1,d0
		addi.w	#SoundTest_NoteSemitoneAdjust,d0
		bpl.s	.fm_index_ok
		moveq	#0,d0
.fm_index_ok:
		divu.w	#12,d0
		move.w	d0,d4
		swap	d0
		andi.w	#$000F,d0
		lsl.w	#1,d0
		lea	SoundTest_NoteLetters(pc),a1
		lea	(v_soundtest_textbuf).w,a0
		move.b	(a1,d0.w),(a0)+
		move.b	1(a1,d0.w),(a0)+
		addi.w	#SoundTest_FMOctaveBias,d4
		move.b	d4,d0
		andi.b	#$0F,d0
		addi.b	#'0',d0
		move.b	d0,(a0)+
		clr.b	(a0)
		rts

SoundTest_FormatPSGNote:
		moveq	#0,d0
		move.w	d1,d0
		addi.w	#0,d0
		bpl.s	.psg_index_ok
		moveq	#0,d0
.psg_index_ok:
		divu.w	#12,d0
		move.w	d0,d4
		swap	d0
		andi.w	#$000F,d0
		lsl.w	#1,d0
		lea	SoundTest_NoteLetters(pc),a1
		lea	(v_soundtest_textbuf).w,a0
		move.b	(a1,d0.w),(a0)+
		move.b	1(a1,d0.w),(a0)+
		addi.w	#SoundTest_PSGOctaveBias,d4
		move.b	d4,d0
		andi.b	#$0F,d0
		addi.b	#'0',d0
		move.b	d0,(a0)+
		clr.b	(a0)
		rts

; ---------------------------------------------------------------------------
; Converts a PSG tone divider into a semitone index (0 = lowest C).
; The note is calculated from the frequency value itself, so it no longer
; depends on how the PSGFrequencies table is ordered.
; input:  d1.w = PSG divider (SMPS_Track.Freq)
; output: d1.w = octave*12 + note (C=0 ... B=11), or -1 if there is no tone
; uses:   d0-d4/a1 (d5 is preserved)
; ---------------------------------------------------------------------------
SoundTest_PSGFreqToIndex:
		move.l	d5,-(sp)
		moveq	#0,d0
		move.w	d1,d0
		beq.s	.invalid
		moveq	#1,d2			; d2 = octave counter
.octave:
		cmpi.w	#440,d0			; bring divider into the reference octave
		bhs.s	.octdone
		add.w	d0,d0			; divider*2 = one octave lower
		addq.w	#1,d2
		bra.s	.octave
.octdone:
		lea	SoundTest_PSGRefDividers(pc),a1
		moveq	#0,d1			; d1 = best note
		move.w	#$7FFF,d4		; d4 = best distance
		moveq	#0,d3			; d3 = current note
.nearest:
		move.w	(a1)+,d5
		sub.w	d0,d5
		bpl.s	.abs
		neg.w	d5
.abs:
		cmp.w	d4,d5
		bhs.s	.notbetter
		move.w	d5,d4
		move.w	d3,d1
.notbetter:
		addq.w	#1,d3
		cmpi.w	#12,d3
		blo.s	.nearest
		mulu.w	#12,d2
		add.w	d2,d1			; index = octave*12 + note
		move.l	(sp)+,d5
		rts
.invalid:
		moveq	#-1,d1
		move.l	(sp)+,d5
		rts

; PSG dividers for C, C#, D, D#, E, F, F#, G, G#, A, A#, B (one octave)
SoundTest_PSGRefDividers:
		dc.w	$356,$326,$2F9,$2CE,$2A5,$280,$25C,$23A,$21A,$1FB,$1DF,$1C4

SoundTest_FormatNoiseNote:
		lea	(v_soundtest_textbuf).w,a0
		move.b	#'N',(a0)+
		move.b	#'-',(a0)+
		andi.w	#$0003,d1
		addi.b	#'0',d1
		move.b	d1,(a0)+
		clr.b	(a0)
		rts

SoundTest_FormatNoiseFrequency:
		bra.w	SoundTest_FormatFrequency

; ---------------------------------------------------------------------------
; Clone Driver / MegaPCM DAC sample lookup.
; Input:  d4.b = SavedDAC sample ID
; Output: a0 = sample-name pointer, d1.w = sample rate in Hz (0 if unused)
; The sample table below mirrors MegaPCM_DAC_Table's conditional flags.
; ---------------------------------------------------------------------------
SoundTest_LookupDACSample:
		moveq	#0,d0
		move.b	d4,d0
		cmpi.w	#SoundTest_DACSample_First,d0
		blo.s	.dac_unknown
		cmpi.w	#SoundTest_DACSample_Last,d0
		bhi.s	.dac_unknown

		lea	SoundTest_DACSampleTable(pc),a1
		move.w	#((SoundTest_DACSampleTable_End-SoundTest_DACSampleTable)/SoundTest_DACSampleEntrySize)-1,d2
.dac_search:
		cmp.b	(a1),d0
		beq.s	.dac_found
		adda.w	#SoundTest_DACSampleEntrySize,a1
		dbf	d2,.dac_search

		; ID is inside the DAC range but not enabled in this ROM's sample set.
		lea	SoundTest_DAC_UNUSED(pc),a0
		moveq	#0,d1
		rts
.dac_found:
		move.w	2(a1),d1
		movea.l	4(a1),a0
		rts
.dac_unknown:
		; Outside the known MegaPCM DAC range: do not invent a sample/rate.
		lea	SoundTest_DAC_UNKNOWN(pc),a0
		moveq	#0,d1
		rts

; ---------------------------------------------------------------------------
; Format a 16-bit sample rate as a right-aligned five-digit decimal + HZ.
; Input: d1.w = Hz. Output: v_soundtest_textbuf = " 8201HZ" / "23784HZ".
; ---------------------------------------------------------------------------
SoundTest_FormatDACRate:
		movem.l	d2-d6/a1,-(sp)
		move.w	d1,d4
		moveq	#0,d5			; leading-zero suppression flag
		moveq	#4,d6			; five decimal digits
		lea	(v_soundtest_textbuf).w,a0
		lea	SoundTest_DACRateDivisors(pc),a1
.dac_rate_digit:
		moveq	#0,d0
		move.w	d4,d0
		move.w	(a1)+,d3
		divu.w	d3,d0			; quotient = digit, remainder = next value
		moveq	#0,d2
		move.w	d0,d2
		swap	d0
		move.w	d0,d4
		tst.w	d5
		bne.s	.dac_rate_write
		tst.w	d2
		bne.s	.dac_rate_start
		move.b	#' ',(a0)+
		bra.s	.dac_rate_next
.dac_rate_start:
		moveq	#1,d5
.dac_rate_write:
		addi.b	#'0',d2
		move.b	d2,(a0)+
.dac_rate_next:
		dbf	d6,.dac_rate_digit
		move.b	#'H',(a0)+
		move.b	#'Z',(a0)+
		clr.b	(a0)
		movem.l	(sp)+,d2-d6/a1
		rts

SoundTest_DACRateDivisors:
		dc.w	10000,1000,100,10,1

SoundTest_FormatByteHex:
		lea	(v_soundtest_textbuf).w,a0
		lea	SoundTest_Hex(pc),a1
		move.w	d1,d0
		lsr.w	#4,d0
		andi.w	#$000F,d0
		move.b	(a1,d0.w),(a0)+
		andi.w	#$000F,d1
		move.b	(a1,d1.w),(a0)+
		clr.b	(a0)
		rts

SoundTest_FormatFrequency:
		lea	(v_soundtest_textbuf).w,a0
		lea	SoundTest_Hex(pc),a1
		move.w	d1,d0
		move.w	d0,d2
		lsr.w	#8,d2
		lsr.w	#4,d2
		andi.w	#$000F,d2
		move.b	(a1,d2.w),(a0)+
		move.w	d0,d2
		lsr.w	#8,d2
		andi.w	#$000F,d2
		move.b	(a1,d2.w),(a0)+
		move.w	d0,d2
		lsr.w	#4,d2
		andi.w	#$000F,d2
		move.b	(a1,d2.w),(a0)+
		andi.w	#$000F,d0
		move.b	(a1,d0.w),(a0)+
		clr.b	(a0)
		rts

; ---------------------------------------------------------------------------
; Draw VDP Graphics and text string handlers
; ---------------------------------------------------------------------------
SoundTest_DrawIcon:
		move.w	d0,d4
		add.w	d4,d4
		move.w	d1,d5
		lsl.w	#7,d5
		add.w	d4,d5
		addi.w	#vram_fg,d5
		move.w	d5,d0
		bsr.w	SoundTest_SetVRAM
		move.w	d3,d0
		addi.w	#SoundTest_IconTile,d0
		or.w	d2,d0
		move.w	d0,(vdp_data_port).l
		rts

SoundTest_DrawText:
		movem.l	d0-d6/a0-a2,-(sp)
		move.w	d0,d6
		add.w	d6,d6
		move.w	d1,d3
		lsl.w	#7,d3
		add.w	d6,d3
		addi.w	#vram_fg,d3
		move.w	d2,d5
		movea.l	a0,a2

		move.w	d3,d0
		bsr.w	SoundTest_SetVRAM
		movea.l	a2,a0
.top:
		moveq	#0,d1
		move.b	(a0)+,d1
		beq.s	.topdone
		cmpi.b	#'a',d1
		blo.s	.notlower_top
		cmpi.b	#'z',d1
		bhi.s	.notlower_top
		subi.b	#$20,d1
.notlower_top:
		cmpi.b	#$7F,d1
		bhi.s	.space_top
		lea	SoundTest_FontMap(pc),a1
		move.b	(a1,d1.w),d1
		addi.w	#SoundTest_ArtTile,d1
		or.w	d5,d1
		move.w	d1,(vdp_data_port).l
		bra.s	.top
.space_top:
		move.w	d5,d1
		ori.w	#SoundTest_ArtTile,d1
		move.w	d1,(vdp_data_port).l
		bra.s	.top
.topdone:

		movea.l	a2,a0
		addi.w	#$80,d3
		move.w	d3,d0
		bsr.w	SoundTest_SetVRAM
.bottom:
		moveq	#0,d1
		move.b	(a0)+,d1
		beq.s	.done
		cmpi.b	#'a',d1
		blo.s	.notlower_bottom
		cmpi.b	#'z',d1
		bhi.s	.notlower_bottom
		subi.b	#$20,d1
.notlower_bottom:
		cmpi.b	#$7F,d1
		bhi.s	.space_bottom
		lea	SoundTest_FontMap(pc),a1
		move.b	(a1,d1.w),d1
		addi.w	#SoundTest_ArtTile+1,d1
		or.w	d5,d1
		move.w	d1,(vdp_data_port).l
		bra.s	.bottom
.space_bottom:
		move.w	d5,d1
		ori.w	#SoundTest_ArtTile+1,d1
		move.w	d1,(vdp_data_port).l
		bra.s	.bottom
.done:
		movem.l	(sp)+,d0-d6/a0-a2
		rts

SoundTest_SetVRAM:
		moveq	#0,d1
		move.w	d0,d1
		andi.l	#$3FFF,d1
		swap	d1
		ori.l	#$40000000,d1
		move.w	d0,d2
		andi.w	#$C000,d2
		lsr.w	#8,d2
		lsr.w	#6,d2
		or.w	d2,d1
		move.l	d1,(vdp_control_port).l
		rts

		include	"soundtest/data/Sound Test Font Mapping.asm"

; ---------------------------------------------------------------------------
; Static Data Block
; ---------------------------------------------------------------------------
SoundTest_Title:        dc.b "SOUND TEST",0
SoundTest_MusicLabel:   dc.b "MUSIC",0
SoundTest_SFXLabel:     dc.b "SFX",0
SoundTest_Help:         dc.b "A+16 B-16 C PLAY",0
SoundTest_StartMenu:    dc.b "START MENU",0
SoundTest_ChannelFM1:   dc.b "FM 1",0
SoundTest_ChannelFM2:   dc.b "FM 2",0
SoundTest_ChannelFM3:   dc.b "FM 3",0
SoundTest_ChannelFM4:   dc.b "FM 4",0
SoundTest_ChannelFM5:   dc.b "FM 5",0
SoundTest_ChannelFM6:   dc.b "FM 6",0
SoundTest_ChannelDAC:   dc.b "DAC ",0
SoundTest_ChannelPSG1:  dc.b "PSG 1",0
SoundTest_ChannelPSG2:  dc.b "PSG 2",0
SoundTest_ChannelNoise: dc.b "PSG 3",0
SoundTest_BlankSelectionHeader: dc.b "      ",0
SoundTest_BlankMusic:   dc.b "                         ",0
SoundTest_Rest:         dc.b "---",0
SoundTest_PCM:          dc.b "PCM",0
SoundTest_DACActive:    dc.b "----",0
SoundTest_DACNameBlank: dc.b "           ",0
SoundTest_DAC_SAMPLE:   dc.b "SAMPLE",0
SoundTest_BlankFreq:    dc.b "    ",0
SoundTest_Hex:          dc.b "0123456789ABCDEF"
SoundTest_NoteLetters:  dc.b "C-C#D-D#E-F-F#G-G#A-A#B-"
		even

; ---------------------------------------------------------------------------
; MegaPCM DAC sample index. IDs, rate values and compile guards mirror
; the uploaded "MegaPCM - DAC Table.asm" source exactly.
; Record format (8 bytes): ID.b, reserved.b, rate.w, display-name pointer.l.
; Disabled sample-set IDs are absent and resolve to UNUSED at runtime.
; ---------------------------------------------------------------------------
SoundTest_DACSampleEntry: macro sampleID,sampleRate,sampleName
	dc.b	sampleID,0
	dc.w	sampleRate
	dc.l	sampleName
	endm

SoundTest_DACSampleTable:
	if SMPS_S1DACSamples||SMPS_S2DACSamples
		SoundTest_DACSampleEntry $81,8201,SoundTest_DAC_81
		SoundTest_DACSampleEntry $82,23784,SoundTest_DAC_82
		SoundTest_DACSampleEntry $85,7328,SoundTest_DAC_85
		SoundTest_DACSampleEntry $88,9635,SoundTest_DAC_88
		SoundTest_DACSampleEntry $89,8720,SoundTest_DAC_89
		SoundTest_DACSampleEntry $8A,7138,SoundTest_DAC_8A
		SoundTest_DACSampleEntry $8B,6957,SoundTest_DAC_8B
	endif
	if SMPS_S2DACSamples
		SoundTest_DACSampleEntry $83,17127,SoundTest_DAC_83
		SoundTest_DACSampleEntry $84,15232,SoundTest_DAC_84
		SoundTest_DACSampleEntry $86,13714,SoundTest_DAC_86
		SoundTest_DACSampleEntry $87,7426,SoundTest_DAC_87
		SoundTest_DACSampleEntry $8C,22799,SoundTest_DAC_8C
		SoundTest_DACSampleEntry $8D,18262,SoundTest_DAC_8D
		SoundTest_DACSampleEntry $8E,15232,SoundTest_DAC_8E
		SoundTest_DACSampleEntry $8F,15232,SoundTest_DAC_8F
		SoundTest_DACSampleEntry $90,13064,SoundTest_DAC_90
		SoundTest_DACSampleEntry $91,9806,SoundTest_DAC_91
	endif
	if SMPS_S3DACSamples||SMPS_SKDACSamples||SMPS_S3DDACSamples
		SoundTest_DACSampleEntry $92,19090,SoundTest_DAC_92
		SoundTest_DACSampleEntry $93,11274,SoundTest_DAC_93
		SoundTest_DACSampleEntry $94,9050,SoundTest_DAC_94
		SoundTest_DACSampleEntry $95,7599,SoundTest_DAC_95
		SoundTest_DACSampleEntry $96,6490,SoundTest_DAC_96
		SoundTest_DACSampleEntry $97,19090,SoundTest_DAC_97
		SoundTest_DACSampleEntry $98,19090,SoundTest_DAC_98
		SoundTest_DACSampleEntry $99,16766,SoundTest_DAC_99
		SoundTest_DACSampleEntry $9A,13482,SoundTest_DAC_9A
		SoundTest_DACSampleEntry $9B,9050,SoundTest_DAC_9B
		SoundTest_DACSampleEntry $9C,7357,SoundTest_DAC_9C
		SoundTest_DACSampleEntry $9D,14945,SoundTest_DAC_9D
		SoundTest_DACSampleEntry $9E,12852,SoundTest_DAC_9E
		SoundTest_DACSampleEntry $9F,10040,SoundTest_DAC_9F
		SoundTest_DACSampleEntry $A0,14945,SoundTest_DAC_A0
		SoundTest_DACSampleEntry $A1,20513,SoundTest_DAC_A1
		SoundTest_DACSampleEntry $A2,15803,SoundTest_DAC_A2
		SoundTest_DACSampleEntry $A3,13482,SoundTest_DAC_A3
		SoundTest_DACSampleEntry $A4,11274,SoundTest_DAC_A4
		SoundTest_DACSampleEntry $A5,16766,SoundTest_DAC_A5
		SoundTest_DACSampleEntry $A6,13482,SoundTest_DAC_A6
		SoundTest_DACSampleEntry $A7,11755,SoundTest_DAC_A7
		SoundTest_DACSampleEntry $A8,9687,SoundTest_DAC_A8
		SoundTest_DACSampleEntry $A9,12852,SoundTest_DAC_A9
		SoundTest_DACSampleEntry $AA,9358,SoundTest_DAC_AA
		SoundTest_DACSampleEntry $AB,8492,SoundTest_DAC_AB
		SoundTest_DACSampleEntry $AC,12279,SoundTest_DAC_AC
		SoundTest_DACSampleEntry $AD,13482,SoundTest_DAC_AD
		SoundTest_DACSampleEntry $AE,7998,SoundTest_DAC_AE
		SoundTest_DACSampleEntry $AF,7998,SoundTest_DAC_AF
	endif
	if SMPS_S3DACSamples||SMPS_SKDACSamples
		SoundTest_DACSampleEntry $B0,12279,SoundTest_DAC_B0
		SoundTest_DACSampleEntry $B1,12279,SoundTest_DAC_B1
		SoundTest_DACSampleEntry $B2,13482,SoundTest_DAC_B2
		SoundTest_DACSampleEntry $B3,13482,SoundTest_DAC_B3
		SoundTest_DACSampleEntry $B4,7998,SoundTest_DAC_B4
		SoundTest_DACSampleEntry $B5,7998,SoundTest_DAC_B5
		SoundTest_DACSampleEntry $B6,12279,SoundTest_DAC_B6
		SoundTest_DACSampleEntry $B7,14176,SoundTest_DAC_B7
		SoundTest_DACSampleEntry $B8,7998,SoundTest_DAC_B8
		SoundTest_DACSampleEntry $B9,7998,SoundTest_DAC_B9
		SoundTest_DACSampleEntry $BA,12279,SoundTest_DAC_BA
		SoundTest_DACSampleEntry $BB,13482,SoundTest_DAC_BB
		SoundTest_DACSampleEntry $BC,11755,SoundTest_DAC_BC
		SoundTest_DACSampleEntry $BD,16766,SoundTest_DAC_BD
		SoundTest_DACSampleEntry $BE,10420,SoundTest_DAC_BE
		SoundTest_DACSampleEntry $BF,7998,SoundTest_DAC_BF
		SoundTest_DACSampleEntry $C0,14176,SoundTest_DAC_C0
		SoundTest_DACSampleEntry $C1,9687,SoundTest_DAC_C1
		SoundTest_DACSampleEntry $C2,7998,SoundTest_DAC_C2
		SoundTest_DACSampleEntry $C3,8492,SoundTest_DAC_C3
		SoundTest_DACSampleEntry $C4,6520,SoundTest_DAC_C4
		SoundTest_DACSampleEntry $C5,12279,SoundTest_DAC_C5
		SoundTest_DACSampleEntry $C6,12279,SoundTest_DAC_C6
		SoundTest_DACSampleEntry $C7,12279,SoundTest_DAC_C7
		SoundTest_DACSampleEntry $C8,7998,SoundTest_DAC_C8
		SoundTest_DACSampleEntry $C9,12279,SoundTest_DAC_C9
		SoundTest_DACSampleEntry $CA,7998,SoundTest_DAC_CA
		SoundTest_DACSampleEntry $CB,7998,SoundTest_DAC_CB
		SoundTest_DACSampleEntry $CC,7998,SoundTest_DAC_CC
		SoundTest_DACSampleEntry $CD,12279,SoundTest_DAC_CD
		SoundTest_DACSampleEntry $CE,12279,SoundTest_DAC_CE
		SoundTest_DACSampleEntry $CF,7166,SoundTest_DAC_CF
		SoundTest_DACSampleEntry $D0,12852,SoundTest_DAC_D0
		SoundTest_DACSampleEntry $D1,10830,SoundTest_DAC_D1
		SoundTest_DACSampleEntry $D2,10040,SoundTest_DAC_D2
		SoundTest_DACSampleEntry $D3,9687,SoundTest_DAC_D3
		SoundTest_DACSampleEntry $D4,12852,SoundTest_DAC_D4
	endif
	if SMPS_S3DDACSamples
		SoundTest_DACSampleEntry $D5,24104,SoundTest_DAC_D5
		SoundTest_DACSampleEntry $D6,9687,SoundTest_DAC_D6
	endif
	if SMPS_S3DACSamples
		SoundTest_DACSampleEntry $D7,8492,SoundTest_DAC_D7
		SoundTest_DACSampleEntry $D8,6490,SoundTest_DAC_D8
	endif
	if SMPS_SCDACSamples
		SoundTest_DACSampleEntry $D9,4728,SoundTest_DAC_D9
		SoundTest_DACSampleEntry $DA,13610,SoundTest_DAC_DA
		SoundTest_DACSampleEntry $DB,13610,SoundTest_DAC_DB
		SoundTest_DACSampleEntry $DC,11363,SoundTest_DAC_DC
		SoundTest_DACSampleEntry $DD,10497,SoundTest_DAC_DD
		SoundTest_DACSampleEntry $DE,13610,SoundTest_DAC_DE
		SoundTest_DACSampleEntry $DF,13610,SoundTest_DAC_DF
	endif
		SoundTest_DACSampleEntry $E0,16000,SoundTest_DAC_E0
SoundTest_DACSampleTable_End:
		even

SoundTest_DAC_UNUSED:         dc.b "UNUSED",0
SoundTest_DAC_UNKNOWN:        dc.b "UNKNOWN",0
SoundTest_DAC_81: dc.b "KICK",0
SoundTest_DAC_82: dc.b "SNARE",0
SoundTest_DAC_85: dc.b "TIMPANI",0
SoundTest_DAC_88: dc.b "HI TIMPANI",0
SoundTest_DAC_89: dc.b "MID TIMPANI",0
SoundTest_DAC_8A: dc.b "LOW TIMPANI",0
SoundTest_DAC_8B: dc.b "VERY LOW",0
SoundTest_DAC_83: dc.b "CLAP",0
SoundTest_DAC_84: dc.b "SCRATCH",0
SoundTest_DAC_86: dc.b "HI TOM",0
SoundTest_DAC_87: dc.b "LOW BONGO",0
SoundTest_DAC_8C: dc.b "MID TOM",0
SoundTest_DAC_8D: dc.b "LOW TOM",0
SoundTest_DAC_8E: dc.b "FLOOR TOM",0
SoundTest_DAC_8F: dc.b "HI BONGO",0
SoundTest_DAC_90: dc.b "MID BONGO",0
SoundTest_DAC_91: dc.b "LOW BONGO",0
SoundTest_DAC_92: dc.b "SNARE S3",0
SoundTest_DAC_93: dc.b "HI TOM S3",0
SoundTest_DAC_94: dc.b "MID TOM S3",0
SoundTest_DAC_95: dc.b "LOW TOM S3",0
SoundTest_DAC_96: dc.b "FLOOR TOM3",0
SoundTest_DAC_97: dc.b "KICK S3",0
SoundTest_DAC_98: dc.b "MUFF SNARE",0
SoundTest_DAC_99: dc.b "CRASH CYMB",0
SoundTest_DAC_9A: dc.b "RIDE CYMBAL",0
SoundTest_DAC_9B: dc.b "LOW METAL",0
SoundTest_DAC_9C: dc.b "METAL HIT",0
SoundTest_DAC_9D: dc.b "HI METAL",0
SoundTest_DAC_9E: dc.b "HI METAL 2",0
SoundTest_DAC_9F: dc.b "MID METAL",0
SoundTest_DAC_A0: dc.b "CLAP S3",0
SoundTest_DAC_A1: dc.b "EL HI TOM",0
SoundTest_DAC_A2: dc.b "EL MID TOM",0
SoundTest_DAC_A3: dc.b "EL LOW TOM",0
SoundTest_DAC_A4: dc.b "EL FLOOR",0
SoundTest_DAC_A5: dc.b "TIGHT SNARE",0
SoundTest_DAC_A6: dc.b "MID SNARE",0
SoundTest_DAC_A7: dc.b "LOOSE SNARE",0
SoundTest_DAC_A8: dc.b "SNARE LOOSE",0
SoundTest_DAC_A9: dc.b "HI TIMPANI",0
SoundTest_DAC_AA: dc.b "LOW TIMPANI",0
SoundTest_DAC_AB: dc.b "MID TIMPANI",0
SoundTest_DAC_AC: dc.b "QUICK SNARE",0
SoundTest_DAC_AD: dc.b "CLICK",0
SoundTest_DAC_AE: dc.b "POWER KICK",0
SoundTest_DAC_AF: dc.b "GLASS CRASH",0
SoundTest_DAC_B0: dc.b "GLASS SNARE",0
SoundTest_DAC_B1: dc.b "GLASS CRASH",0
SoundTest_DAC_B2: dc.b "GLASS KICK",0
SoundTest_DAC_B3: dc.b "QUIET GLASS",0
SoundTest_DAC_B4: dc.b "SNARE+KICK",0
SoundTest_DAC_B5: dc.b "BASS KICK",0
SoundTest_DAC_B6: dc.b "COME ON",0
SoundTest_DAC_B7: dc.b "DANCE SNARE",0
SoundTest_DAC_B8: dc.b "LOOSE KICK",0
SoundTest_DAC_B9: dc.b "MOD KICK",0
SoundTest_DAC_BA: dc.b "WOO",0
SoundTest_DAC_BB: dc.b "GO",0
SoundTest_DAC_BC: dc.b "SNARE+GO",0
SoundTest_DAC_BD: dc.b "POWER TOM",0
SoundTest_DAC_BE: dc.b "HI WOOD",0
SoundTest_DAC_BF: dc.b "LOW WOOD",0
SoundTest_DAC_C0: dc.b "HI HIT DRUM",0
SoundTest_DAC_C1: dc.b "LOW HIT",0
SoundTest_DAC_C2: dc.b "METAL CRASH",0
SoundTest_DAC_C3: dc.b "ECHO CLAP",0
SoundTest_DAC_C4: dc.b "LOW ECHO",0
SoundTest_DAC_C5: dc.b "HIPHOP KICK",0
SoundTest_DAC_C6: dc.b "HIPHOP PWR",0
SoundTest_DAC_C7: dc.b "BASS+HEY",0
SoundTest_DAC_C8: dc.b "DANCE KICK",0
SoundTest_DAC_C9: dc.b "HIPHOP KIK2",0
SoundTest_DAC_CA: dc.b "REV WIND",0
SoundTest_DAC_CB: dc.b "SCRATCH S3",0
SoundTest_DAC_CC: dc.b "SNARE NOISE",0
SoundTest_DAC_CD: dc.b "POWER KICK2",0
SoundTest_DAC_CE: dc.b "CRASH+WOO",0
SoundTest_DAC_CF: dc.b "QUICK HIT",0
SoundTest_DAC_D0: dc.b "KICK+HEY",0
SoundTest_DAC_D1: dc.b "POWER HIT",0
SoundTest_DAC_D2: dc.b "LOW PWR HIT",0
SoundTest_DAC_D3: dc.b "LOWER PWR",0
SoundTest_DAC_D4: dc.b "LOWEST PWR",0
SoundTest_DAC_D5: dc.b "FINAL METAL",0
SoundTest_DAC_D6: dc.b "INTRO KICK",0
SoundTest_DAC_D7: dc.b "ECHO CLAP3",0
SoundTest_DAC_D8: dc.b "LOW ECHO3",0
SoundTest_DAC_D9: dc.b "BEAT",0
SoundTest_DAC_DA: dc.b "SNARE SC",0
SoundTest_DAC_DB: dc.b "HI TIMP TOM",0
SoundTest_DAC_DC: dc.b "MID TIMP",0
SoundTest_DAC_DD: dc.b "LOW TIMP",0
SoundTest_DAC_DE: dc.b "LETS GO",0
SoundTest_DAC_DF: dc.b "HEY",0
SoundTest_DAC_E0: dc.b "SEGA!",0
SoundTest_DACRateBlank:    dc.b "        ",0
		even

		include "soundtest/data/entries/Sound Test Entries.asm"
		even

SoundTest_Art_Nem:
		binclude	"soundtest/data/Sound Test Font Icons.nem"
		even
SoundTest_Art_Nem_End:

SoundTest_Tilemap:
		binclude	"soundtest/data/Sound Test Tilemap.bin"
		even