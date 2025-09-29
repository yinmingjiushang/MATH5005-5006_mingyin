
dsyevd_test.exe:     file format pei-x86-64


Disassembly of section .text:

0000000140001450 <dsyevd_>:
   140001450:	41 57                	push   r15
   140001452:	41 56                	push   r14
   140001454:	41 55                	push   r13
   140001456:	41 54                	push   r12
   140001458:	55                   	push   rbp
   140001459:	57                   	push   rdi
   14000145a:	56                   	push   rsi
   14000145b:	53                   	push   rbx
   14000145c:	48 81 ec c8 00 00 00 	sub    rsp,0xc8
   140001463:	bf 01 00 00 00       	mov    edi,0x1
   140001468:	48 8b ac 24 60 01 00 	mov    rbp,QWORD PTR [rsp+0x160]
   14000146f:	00 
   140001470:	48 89 d6             	mov    rsi,rdx
   140001473:	4c 89 c3             	mov    rbx,r8
   140001476:	48 8d 15 e3 2c 22 01 	lea    rdx,[rip+0x1222ce3]        # 141224160 <.rdata>
   14000147d:	4d 89 cc             	mov    r12,r9
   140001480:	41 b8 01 00 00 00    	mov    r8d,0x1
   140001486:	41 b9 01 00 00 00    	mov    r9d,0x1
   14000148c:	49 89 ce             	mov    r14,rcx
   14000148f:	e8 dc 4c 01 00       	call   140016170 <lsame_>
   140001494:	41 b9 01 00 00 00    	mov    r9d,0x1
   14000149a:	41 b8 01 00 00 00    	mov    r8d,0x1
   1400014a0:	48 89 f1             	mov    rcx,rsi
   1400014a3:	48 8d 15 b7 2c 22 01 	lea    rdx,[rip+0x1222cb7]        # 141224161 <.rdata+0x1>
   1400014aa:	41 89 c5             	mov    r13d,eax
   1400014ad:	e8 be 4c 01 00       	call   140016170 <lsame_>
   1400014b2:	41 89 c2             	mov    r10d,eax
   1400014b5:	48 8b 84 24 48 01 00 	mov    rax,QWORD PTR [rsp+0x148]
   1400014bc:	00 
   1400014bd:	83 38 ff             	cmp    DWORD PTR [rax],0xffffffff
   1400014c0:	74 0f                	je     1400014d1 <dsyevd_+0x81>
   1400014c2:	48 8b 84 24 58 01 00 	mov    rax,QWORD PTR [rsp+0x158]
   1400014c9:	00 
   1400014ca:	83 38 ff             	cmp    DWORD PTR [rax],0xffffffff
   1400014cd:	40 0f 94 c7          	sete   dil
   1400014d1:	c7 45 00 00 00 00 00 	mov    DWORD PTR [rbp+0x0],0x0
   1400014d8:	83 e7 01             	and    edi,0x1
   1400014db:	45 85 ed             	test   r13d,r13d
   1400014de:	0f 84 6c 01 00 00    	je     140001650 <dsyevd_+0x200>
   1400014e4:	45 85 d2             	test   r10d,r10d
   1400014e7:	0f 84 c3 01 00 00    	je     1400016b0 <dsyevd_+0x260>
   1400014ed:	44 8b 13             	mov    r10d,DWORD PTR [rbx]
   1400014f0:	45 85 d2             	test   r10d,r10d
   1400014f3:	78 5b                	js     140001550 <dsyevd_+0x100>
   1400014f5:	48 8b 8c 24 30 01 00 	mov    rcx,QWORD PTR [rsp+0x130]
   1400014fc:	00 
   1400014fd:	b8 01 00 00 00       	mov    eax,0x1
   140001502:	41 0f 4f c2          	cmovg  eax,r10d
   140001506:	39 01                	cmp    DWORD PTR [rcx],eax
   140001508:	7d 56                	jge    140001560 <dsyevd_+0x110>
   14000150a:	ba fb ff ff ff       	mov    edx,0xfffffffb
   14000150f:	b8 05 00 00 00       	mov    eax,0x5
   140001514:	89 55 00             	mov    DWORD PTR [rbp+0x0],edx
   140001517:	48 8d 94 24 b8 00 00 	lea    rdx,[rsp+0xb8]
   14000151e:	00 
   14000151f:	41 b8 06 00 00 00    	mov    r8d,0x6
   140001525:	48 8d 0d 48 2c 22 01 	lea    rcx,[rip+0x1222c48]        # 141224174 <.rdata+0x14>
   14000152c:	89 84 24 b8 00 00 00 	mov    DWORD PTR [rsp+0xb8],eax
   140001533:	e8 c8 2b 01 00       	call   140014100 <xerbla_>
   140001538:	90                   	nop
   140001539:	48 81 c4 c8 00 00 00 	add    rsp,0xc8
   140001540:	5b                   	pop    rbx
   140001541:	5e                   	pop    rsi
   140001542:	5f                   	pop    rdi
   140001543:	5d                   	pop    rbp
   140001544:	41 5c                	pop    r12
   140001546:	41 5d                	pop    r13
   140001548:	41 5e                	pop    r14
   14000154a:	41 5f                	pop    r15
   14000154c:	c3                   	ret
   14000154d:	0f 1f 00             	nop    DWORD PTR [rax]
   140001550:	ba fd ff ff ff       	mov    edx,0xfffffffd
   140001555:	b8 03 00 00 00       	mov    eax,0x3
   14000155a:	eb b8                	jmp    140001514 <dsyevd_+0xc4>
   14000155c:	0f 1f 40 00          	nop    DWORD PTR [rax+0x0]
   140001560:	8b 45 00             	mov    eax,DWORD PTR [rbp+0x0]
   140001563:	85 c0                	test   eax,eax
   140001565:	0f 85 35 01 00 00    	jne    1400016a0 <dsyevd_+0x250>
   14000156b:	41 83 fa 01          	cmp    r10d,0x1
   14000156f:	0f 8e 1b 04 00 00    	jle    140001990 <dsyevd_+0x540>
   140001575:	45 85 ed             	test   r13d,r13d
   140001578:	0f 84 6a 01 00 00    	je     1400016e8 <dsyevd_+0x298>
   14000157e:	44 89 d0             	mov    eax,r10d
   140001581:	43 8d 14 52          	lea    edx,[r10+r10*2]
   140001585:	47 8d 74 92 03       	lea    r14d,[r10+r10*4+0x3]
   14000158a:	41 0f af c2          	imul   eax,r10d
   14000158e:	01 c0                	add    eax,eax
   140001590:	44 8d 5c 50 01       	lea    r11d,[rax+rdx*2+0x1]
   140001595:	48 8d 05 d4 2b 22 01 	lea    rax,[rip+0x1222bd4]        # 141224170 <.rdata+0x10>
   14000159c:	49 89 d9             	mov    r9,rbx
   14000159f:	48 8d 15 be 2b 22 01 	lea    rdx,[rip+0x1222bbe]        # 141224164 <.rdata+0x4>
   1400015a6:	49 89 f0             	mov    r8,rsi
   1400015a9:	48 c7 44 24 40 01 00 	mov    QWORD PTR [rsp+0x40],0x1
   1400015b0:	00 00 
   1400015b2:	48 8d 0d b3 2b 22 01 	lea    rcx,[rip+0x1222bb3]        # 14122416c <.rdata+0xc>
   1400015b9:	48 c7 44 24 38 06 00 	mov    QWORD PTR [rsp+0x38],0x6
   1400015c0:	00 00 
   1400015c2:	48 89 44 24 30       	mov    QWORD PTR [rsp+0x30],rax
   1400015c7:	48 89 44 24 28       	mov    QWORD PTR [rsp+0x28],rax
   1400015cc:	48 89 44 24 20       	mov    QWORD PTR [rsp+0x20],rax
   1400015d1:	44 89 9c 24 88 00 00 	mov    DWORD PTR [rsp+0x88],r11d
   1400015d8:	00 
   1400015d9:	44 89 94 24 84 00 00 	mov    DWORD PTR [rsp+0x84],r10d
   1400015e0:	00 
   1400015e1:	e8 da 52 00 00       	call   1400068c0 <ilaenv_>
   1400015e6:	44 8b 9c 24 88 00 00 	mov    r11d,DWORD PTR [rsp+0x88]
   1400015ed:	00 
   1400015ee:	66 0f ef c0          	pxor   xmm0,xmm0
   1400015f2:	83 c0 02             	add    eax,0x2
   1400015f5:	0f af 84 24 84 00 00 	imul   eax,DWORD PTR [rsp+0x84]
   1400015fc:	00 
   1400015fd:	44 39 d8             	cmp    eax,r11d
   140001600:	41 0f 4c c3          	cmovl  eax,r11d
   140001604:	89 84 24 84 00 00 00 	mov    DWORD PTR [rsp+0x84],eax
   14000160b:	f2 0f 2a c0          	cvtsi2sd xmm0,eax
   14000160f:	48 8b 84 24 40 01 00 	mov    rax,QWORD PTR [rsp+0x140]
   140001616:	00 
   140001617:	f2 0f 11 00          	movsd  QWORD PTR [rax],xmm0
   14000161b:	48 8b 84 24 50 01 00 	mov    rax,QWORD PTR [rsp+0x150]
   140001622:	00 
   140001623:	44 89 30             	mov    DWORD PTR [rax],r14d
   140001626:	48 8b 84 24 48 01 00 	mov    rax,QWORD PTR [rsp+0x148]
   14000162d:	00 
   14000162e:	44 39 18             	cmp    DWORD PTR [rax],r11d
   140001631:	0f 8d c9 00 00 00    	jge    140001700 <dsyevd_+0x2b0>
   140001637:	85 ff                	test   edi,edi
   140001639:	0f 85 79 03 00 00    	jne    1400019b8 <dsyevd_+0x568>
   14000163f:	c7 45 00 f8 ff ff ff 	mov    DWORD PTR [rbp+0x0],0xfffffff8
   140001646:	b8 08 00 00 00       	mov    eax,0x8
   14000164b:	e9 c7 fe ff ff       	jmp    140001517 <dsyevd_+0xc7>
   140001650:	41 b9 01 00 00 00    	mov    r9d,0x1
   140001656:	41 b8 01 00 00 00    	mov    r8d,0x1
   14000165c:	4c 89 f1             	mov    rcx,r14
   14000165f:	44 89 94 24 84 00 00 	mov    DWORD PTR [rsp+0x84],r10d
   140001666:	00 
   140001667:	48 8d 15 f4 2a 22 01 	lea    rdx,[rip+0x1222af4]        # 141224162 <.rdata+0x2>
   14000166e:	e8 fd 4a 01 00       	call   140016170 <lsame_>
   140001673:	44 8b 94 24 84 00 00 	mov    r10d,DWORD PTR [rsp+0x84]
   14000167a:	00 
   14000167b:	85 c0                	test   eax,eax
   14000167d:	0f 85 61 fe ff ff    	jne    1400014e4 <dsyevd_+0x94>
   140001683:	c7 45 00 ff ff ff ff 	mov    DWORD PTR [rbp+0x0],0xffffffff
   14000168a:	41 bf ff ff ff ff    	mov    r15d,0xffffffff
   140001690:	44 89 f8             	mov    eax,r15d
   140001693:	66 90                	xchg   ax,ax
   140001695:	66 66 2e 0f 1f 84 00 	data16 cs nop WORD PTR [rax+rax*1+0x0]
   14000169c:	00 00 00 00 
   1400016a0:	f7 d8                	neg    eax
   1400016a2:	e9 70 fe ff ff       	jmp    140001517 <dsyevd_+0xc7>
   1400016a7:	66 0f 1f 84 00 00 00 	nop    WORD PTR [rax+rax*1+0x0]
   1400016ae:	00 00 
   1400016b0:	41 b9 01 00 00 00    	mov    r9d,0x1
   1400016b6:	41 b8 01 00 00 00    	mov    r8d,0x1
   1400016bc:	48 8d 15 a0 2a 22 01 	lea    rdx,[rip+0x1222aa0]        # 141224163 <.rdata+0x3>
   1400016c3:	48 89 f1             	mov    rcx,rsi
   1400016c6:	e8 a5 4a 01 00       	call   140016170 <lsame_>
   1400016cb:	85 c0                	test   eax,eax
   1400016cd:	0f 85 1a fe ff ff    	jne    1400014ed <dsyevd_+0x9d>
   1400016d3:	ba fe ff ff ff       	mov    edx,0xfffffffe
   1400016d8:	b8 02 00 00 00       	mov    eax,0x2
   1400016dd:	e9 32 fe ff ff       	jmp    140001514 <dsyevd_+0xc4>
   1400016e2:	66 0f 1f 44 00 00    	nop    WORD PTR [rax+rax*1+0x0]
   1400016e8:	47 8d 5c 12 01       	lea    r11d,[r10+r10*1+0x1]
   1400016ed:	41 be 01 00 00 00    	mov    r14d,0x1
   1400016f3:	e9 9d fe ff ff       	jmp    140001595 <dsyevd_+0x145>
   1400016f8:	0f 1f 84 00 00 00 00 	nop    DWORD PTR [rax+rax*1+0x0]
   1400016ff:	00 
   140001700:	48 8b 84 24 58 01 00 	mov    rax,QWORD PTR [rsp+0x158]
   140001707:	00 
   140001708:	44 39 30             	cmp    DWORD PTR [rax],r14d
   14000170b:	7d 23                	jge    140001730 <dsyevd_+0x2e0>
   14000170d:	85 ff                	test   edi,edi
   14000170f:	0f 85 a3 02 00 00    	jne    1400019b8 <dsyevd_+0x568>
   140001715:	c7 45 00 f6 ff ff ff 	mov    DWORD PTR [rbp+0x0],0xfffffff6
   14000171c:	b8 0a 00 00 00       	mov    eax,0xa
   140001721:	e9 f1 fd ff ff       	jmp    140001517 <dsyevd_+0xc7>
   140001726:	66 2e 0f 1f 84 00 00 	cs nop WORD PTR [rax+rax*1+0x0]
   14000172d:	00 00 00 
   140001730:	8b 45 00             	mov    eax,DWORD PTR [rbp+0x0]
   140001733:	41 89 c7             	mov    r15d,eax
   140001736:	85 c0                	test   eax,eax
   140001738:	0f 85 52 ff ff ff    	jne    140001690 <dsyevd_+0x240>
   14000173e:	85 ff                	test   edi,edi
   140001740:	0f 85 f3 fd ff ff    	jne    140001539 <dsyevd_+0xe9>
   140001746:	8b 03                	mov    eax,DWORD PTR [rbx]
   140001748:	85 c0                	test   eax,eax
   14000174a:	0f 84 e9 fd ff ff    	je     140001539 <dsyevd_+0xe9>
   140001750:	83 f8 01             	cmp    eax,0x1
   140001753:	0f 84 77 02 00 00    	je     1400019d0 <dsyevd_+0x580>
   140001759:	ba 0c 00 00 00       	mov    edx,0xc
   14000175e:	48 8d 0d 15 2a 22 01 	lea    rcx,[rip+0x1222a15]        # 14122417a <.rdata+0x1a>
   140001765:	e8 76 4f 00 00       	call   1400066e0 <dlamch_>
   14000176a:	ba 09 00 00 00       	mov    edx,0x9
   14000176f:	48 8d 0d 10 2a 22 01 	lea    rcx,[rip+0x1222a10]        # 141224186 <.rdata+0x26>
   140001776:	66 48 0f 7e c7       	movq   rdi,xmm0
   14000177b:	e8 60 4f 00 00       	call   1400066e0 <dlamch_>
   140001780:	66 48 0f 6e cf       	movq   xmm1,rdi
   140001785:	4d 89 e1             	mov    r9,r12
   140001788:	49 89 d8             	mov    r8,rbx
   14000178b:	f2 0f 5e c8          	divsd  xmm1,xmm0
   14000178f:	48 89 f2             	mov    rdx,rsi
   140001792:	48 8b 84 24 40 01 00 	mov    rax,QWORD PTR [rsp+0x140]
   140001799:	00 
   14000179a:	48 c7 44 24 38 01 00 	mov    QWORD PTR [rsp+0x38],0x1
   1400017a1:	00 00 
   1400017a3:	48 c7 44 24 30 01 00 	mov    QWORD PTR [rsp+0x30],0x1
   1400017aa:	00 00 
   1400017ac:	48 8d 0d dc 29 22 01 	lea    rcx,[rip+0x12229dc]        # 14122418f <.rdata+0x2f>
   1400017b3:	48 89 44 24 28       	mov    QWORD PTR [rsp+0x28],rax
   1400017b8:	48 8b 84 24 30 01 00 	mov    rax,QWORD PTR [rsp+0x130]
   1400017bf:	00 
   1400017c0:	48 89 44 24 20       	mov    QWORD PTR [rsp+0x20],rax
   1400017c5:	f2 0f 11 8c 24 88 00 	movsd  QWORD PTR [rsp+0x88],xmm1
   1400017cc:	00 00 
   1400017ce:	e8 ed d1 d8 00       	call   140d8e9c0 <dlansy_>
   1400017d3:	f2 0f 10 8c 24 88 00 	movsd  xmm1,QWORD PTR [rsp+0x88]
   1400017da:	00 00 
   1400017dc:	66 0f 28 d0          	movapd xmm2,xmm0
   1400017e0:	66 0f ef c0          	pxor   xmm0,xmm0
   1400017e4:	66 0f 2f d0          	comisd xmm2,xmm0
   1400017e8:	76 0e                	jbe    1400017f8 <dsyevd_+0x3a8>
   1400017ea:	66 0f 28 c1          	movapd xmm0,xmm1
   1400017ee:	f2 0f 51 c0          	sqrtsd xmm0,xmm0
   1400017f2:	66 0f 2f c2          	comisd xmm0,xmm2
   1400017f6:	77 16                	ja     14000180e <dsyevd_+0x3be>
   1400017f8:	f2 0f 10 05 a0 29 22 	movsd  xmm0,QWORD PTR [rip+0x12229a0]        # 1412241a0 <.rdata+0x40>
   1400017ff:	01 
   140001800:	f2 0f 5e c1          	divsd  xmm0,xmm1
   140001804:	f2 0f 51 c0          	sqrtsd xmm0,xmm0
   140001808:	66 0f 2f d0          	comisd xmm2,xmm0
   14000180c:	76 63                	jbe    140001871 <dsyevd_+0x421>
   14000180e:	f2 0f 5e c2          	divsd  xmm0,xmm2
   140001812:	48 8b 84 24 30 01 00 	mov    rax,QWORD PTR [rsp+0x130]
   140001819:	00 
   14000181a:	48 89 6c 24 48       	mov    QWORD PTR [rsp+0x48],rbp
   14000181f:	4c 8d 05 72 29 22 01 	lea    r8,[rip+0x1222972]        # 141224198 <.rdata+0x38>
   140001826:	48 c7 44 24 50 01 00 	mov    QWORD PTR [rsp+0x50],0x1
   14000182d:	00 00 
   14000182f:	4c 8d 0d 5a 29 22 01 	lea    r9,[rip+0x122295a]        # 141224190 <.rdata+0x30>
   140001836:	4c 89 c2             	mov    rdx,r8
   140001839:	48 89 f1             	mov    rcx,rsi
   14000183c:	48 89 44 24 40       	mov    QWORD PTR [rsp+0x40],rax
   140001841:	48 8d 84 24 b0 00 00 	lea    rax,[rsp+0xb0]
   140001848:	00 
   140001849:	41 bf 01 00 00 00    	mov    r15d,0x1
   14000184f:	4c 89 64 24 38       	mov    QWORD PTR [rsp+0x38],r12
   140001854:	48 89 5c 24 30       	mov    QWORD PTR [rsp+0x30],rbx
   140001859:	48 89 5c 24 28       	mov    QWORD PTR [rsp+0x28],rbx
   14000185e:	48 89 44 24 20       	mov    QWORD PTR [rsp+0x20],rax
   140001863:	f2 0f 11 84 24 b0 00 	movsd  QWORD PTR [rsp+0xb0],xmm0
   14000186a:	00 00 
   14000186c:	e8 2f 10 00 00       	call   1400028a0 <dlascl_>
   140001871:	48 63 03             	movsxd rax,DWORD PTR [rbx]
   140001874:	48 8b bc 24 48 01 00 	mov    rdi,QWORD PTR [rsp+0x148]
   14000187b:	00 
   14000187c:	4c 8b 8c 24 30 01 00 	mov    r9,QWORD PTR [rsp+0x130]
   140001883:	00 
   140001884:	41 89 c2             	mov    r10d,eax
   140001887:	8b 17                	mov    edx,DWORD PTR [rdi]
   140001889:	8d 4c 00 01          	lea    ecx,[rax+rax*1+0x1]
   14000188d:	48 8b bc 24 40 01 00 	mov    rdi,QWORD PTR [rsp+0x140]
   140001894:	00 
   140001895:	48 c7 44 24 50 01 00 	mov    QWORD PTR [rsp+0x50],0x1
   14000189c:	00 00 
   14000189e:	44 0f af d0          	imul   r10d,eax
   1400018a2:	41 89 d0             	mov    r8d,edx
   1400018a5:	41 29 c8             	sub    r8d,ecx
   1400018a8:	41 01 ca             	add    r10d,ecx
   1400018ab:	48 63 c9             	movsxd rcx,ecx
   1400018ae:	41 83 c0 01          	add    r8d,0x1
   1400018b2:	44 29 d2             	sub    edx,r10d
   1400018b5:	48 8d 7c cf f8       	lea    rdi,[rdi+rcx*8-0x8]
   1400018ba:	44 89 84 24 a8 00 00 	mov    DWORD PTR [rsp+0xa8],r8d
   1400018c1:	00 
   1400018c2:	4d 89 e0             	mov    r8,r12
   1400018c5:	83 c2 01             	add    edx,0x1
   1400018c8:	48 89 7c 24 38       	mov    QWORD PTR [rsp+0x38],rdi
   1400018cd:	89 94 24 ac 00 00 00 	mov    DWORD PTR [rsp+0xac],edx
   1400018d4:	48 8b 94 24 40 01 00 	mov    rdx,QWORD PTR [rsp+0x140]
   1400018db:	00 
   1400018dc:	44 89 94 24 88 00 00 	mov    DWORD PTR [rsp+0x88],r10d
   1400018e3:	00 
   1400018e4:	48 8d 0c c2          	lea    rcx,[rdx+rax*8]
   1400018e8:	48 8d 84 24 a4 00 00 	lea    rax,[rsp+0xa4]
   1400018ef:	00 
   1400018f0:	48 89 54 24 28       	mov    QWORD PTR [rsp+0x28],rdx
   1400018f5:	48 89 da             	mov    rdx,rbx
   1400018f8:	48 89 84 24 98 00 00 	mov    QWORD PTR [rsp+0x98],rax
   1400018ff:	00 
   140001900:	48 89 44 24 48       	mov    QWORD PTR [rsp+0x48],rax
   140001905:	48 8d 84 24 a8 00 00 	lea    rax,[rsp+0xa8]
   14000190c:	00 
   14000190d:	48 89 44 24 40       	mov    QWORD PTR [rsp+0x40],rax
   140001912:	48 8b 84 24 38 01 00 	mov    rax,QWORD PTR [rsp+0x138]
   140001919:	00 
   14000191a:	48 89 4c 24 30       	mov    QWORD PTR [rsp+0x30],rcx
   14000191f:	48 89 44 24 20       	mov    QWORD PTR [rsp+0x20],rax
   140001924:	48 89 8c 24 90 00 00 	mov    QWORD PTR [rsp+0x90],rcx
   14000192b:	00 
   14000192c:	48 89 f1             	mov    rcx,rsi
   14000192f:	e8 4c 02 00 00       	call   140001b80 <dsytrd_>
   140001934:	45 85 ed             	test   r13d,r13d
   140001937:	0f 85 c3 00 00 00    	jne    140001a00 <dsyevd_+0x5b0>
   14000193d:	4c 8b 84 24 40 01 00 	mov    r8,QWORD PTR [rsp+0x140]
   140001944:	00 
   140001945:	48 8b 94 24 38 01 00 	mov    rdx,QWORD PTR [rsp+0x138]
   14000194c:	00 
   14000194d:	49 89 e9             	mov    r9,rbp
   140001950:	48 89 d9             	mov    rcx,rbx
   140001953:	e8 e8 3e 00 00       	call   140005840 <dsterf_>
   140001958:	41 83 ff 01          	cmp    r15d,0x1
   14000195c:	0f 84 ce 01 00 00    	je     140001b30 <dsyevd_+0x6e0>
   140001962:	48 8b 84 24 40 01 00 	mov    rax,QWORD PTR [rsp+0x140]
   140001969:	00 
   14000196a:	66 0f ef c0          	pxor   xmm0,xmm0
   14000196e:	f2 0f 2a 84 24 84 00 	cvtsi2sd xmm0,DWORD PTR [rsp+0x84]
   140001975:	00 00 
   140001977:	f2 0f 11 00          	movsd  QWORD PTR [rax],xmm0
   14000197b:	48 8b 84 24 50 01 00 	mov    rax,QWORD PTR [rsp+0x150]
   140001982:	00 
   140001983:	44 89 30             	mov    DWORD PTR [rax],r14d
   140001986:	e9 ae fb ff ff       	jmp    140001539 <dsyevd_+0xe9>
   14000198b:	0f 1f 44 00 00       	nop    DWORD PTR [rax+rax*1+0x0]
   140001990:	f2 0f 10 05 08 28 22 	movsd  xmm0,QWORD PTR [rip+0x1222808]        # 1412241a0 <.rdata+0x40>
   140001997:	01 
   140001998:	41 bb 01 00 00 00    	mov    r11d,0x1
   14000199e:	c7 84 24 84 00 00 00 	mov    DWORD PTR [rsp+0x84],0x1
   1400019a5:	01 00 00 00 
   1400019a9:	41 be 01 00 00 00    	mov    r14d,0x1
   1400019af:	e9 5b fc ff ff       	jmp    14000160f <dsyevd_+0x1bf>
   1400019b4:	0f 1f 40 00          	nop    DWORD PTR [rax+0x0]
   1400019b8:	8b 45 00             	mov    eax,DWORD PTR [rbp+0x0]
   1400019bb:	85 c0                	test   eax,eax
   1400019bd:	0f 84 76 fb ff ff    	je     140001539 <dsyevd_+0xe9>
   1400019c3:	e9 d8 fc ff ff       	jmp    1400016a0 <dsyevd_+0x250>
   1400019c8:	0f 1f 84 00 00 00 00 	nop    DWORD PTR [rax+rax*1+0x0]
   1400019cf:	00 
   1400019d0:	f2 41 0f 10 04 24    	movsd  xmm0,QWORD PTR [r12]
   1400019d6:	48 8b 84 24 38 01 00 	mov    rax,QWORD PTR [rsp+0x138]
   1400019dd:	00 
   1400019de:	f2 0f 11 00          	movsd  QWORD PTR [rax],xmm0
   1400019e2:	45 85 ed             	test   r13d,r13d
   1400019e5:	0f 84 4e fb ff ff    	je     140001539 <dsyevd_+0xe9>
   1400019eb:	48 8b 05 ae 27 22 01 	mov    rax,QWORD PTR [rip+0x12227ae]        # 1412241a0 <.rdata+0x40>
   1400019f2:	49 89 04 24          	mov    QWORD PTR [r12],rax
   1400019f6:	e9 3e fb ff ff       	jmp    140001539 <dsyevd_+0xe9>
   1400019fb:	0f 1f 44 00 00       	nop    DWORD PTR [rax+rax*1+0x0]
   140001a00:	4c 63 94 24 88 00 00 	movsxd r10,DWORD PTR [rsp+0x88]
   140001a07:	00 
   140001a08:	48 89 6c 24 50       	mov    QWORD PTR [rsp+0x50],rbp
   140001a0d:	48 89 da             	mov    rdx,rbx
   140001a10:	48 8d ac 24 ac 00 00 	lea    rbp,[rsp+0xac]
   140001a17:	00 
   140001a18:	48 8b 84 24 40 01 00 	mov    rax,QWORD PTR [rsp+0x140]
   140001a1f:	00 
   140001a20:	48 89 6c 24 38       	mov    QWORD PTR [rsp+0x38],rbp
   140001a25:	48 8d 0d 70 27 22 01 	lea    rcx,[rip+0x1222770]        # 14122419c <.rdata+0x3c>
   140001a2c:	48 89 5c 24 28       	mov    QWORD PTR [rsp+0x28],rbx
   140001a31:	4c 8b 8c 24 40 01 00 	mov    r9,QWORD PTR [rsp+0x140]
   140001a38:	00 
   140001a39:	4e 8d 6c d0 f8       	lea    r13,[rax+r10*8-0x8]
   140001a3e:	48 8b 84 24 58 01 00 	mov    rax,QWORD PTR [rsp+0x158]
   140001a45:	00 
   140001a46:	48 c7 44 24 58 01 00 	mov    QWORD PTR [rsp+0x58],0x1
   140001a4d:	00 00 
   140001a4f:	4c 89 6c 24 30       	mov    QWORD PTR [rsp+0x30],r13
   140001a54:	4c 8b 84 24 38 01 00 	mov    r8,QWORD PTR [rsp+0x138]
   140001a5b:	00 
   140001a5c:	48 89 44 24 48       	mov    QWORD PTR [rsp+0x48],rax
   140001a61:	48 8b 84 24 50 01 00 	mov    rax,QWORD PTR [rsp+0x150]
   140001a68:	00 
   140001a69:	48 89 7c 24 20       	mov    QWORD PTR [rsp+0x20],rdi
   140001a6e:	48 89 44 24 40       	mov    QWORD PTR [rsp+0x40],rax
   140001a73:	e8 68 17 00 00       	call   1400031e0 <dstedc_>
   140001a78:	48 89 6c 24 58       	mov    QWORD PTR [rsp+0x58],rbp
   140001a7d:	49 89 d9             	mov    r9,rbx
   140001a80:	48 89 f2             	mov    rdx,rsi
   140001a83:	48 8b 84 24 98 00 00 	mov    rax,QWORD PTR [rsp+0x98]
   140001a8a:	00 
   140001a8b:	4c 89 6c 24 50       	mov    QWORD PTR [rsp+0x50],r13
   140001a90:	4c 8d 05 cb 26 22 01 	lea    r8,[rip+0x12226cb]        # 141224162 <.rdata+0x2>
   140001a97:	48 8d 0d c3 26 22 01 	lea    rcx,[rip+0x12226c3]        # 141224161 <.rdata+0x1>
   140001a9e:	48 c7 44 24 78 01 00 	mov    QWORD PTR [rsp+0x78],0x1
   140001aa5:	00 00 
   140001aa7:	48 89 44 24 60       	mov    QWORD PTR [rsp+0x60],rax
   140001aac:	48 8b 84 24 90 00 00 	mov    rax,QWORD PTR [rsp+0x90]
   140001ab3:	00 
   140001ab4:	48 c7 44 24 70 01 00 	mov    QWORD PTR [rsp+0x70],0x1
   140001abb:	00 00 
   140001abd:	48 89 44 24 38       	mov    QWORD PTR [rsp+0x38],rax
   140001ac2:	48 8b 84 24 30 01 00 	mov    rax,QWORD PTR [rsp+0x130]
   140001ac9:	00 
   140001aca:	48 c7 44 24 68 01 00 	mov    QWORD PTR [rsp+0x68],0x1
   140001ad1:	00 00 
   140001ad3:	48 89 44 24 30       	mov    QWORD PTR [rsp+0x30],rax
   140001ad8:	48 89 5c 24 48       	mov    QWORD PTR [rsp+0x48],rbx
   140001add:	48 89 7c 24 40       	mov    QWORD PTR [rsp+0x40],rdi
   140001ae2:	4c 89 64 24 28       	mov    QWORD PTR [rsp+0x28],r12
   140001ae7:	48 89 5c 24 20       	mov    QWORD PTR [rsp+0x20],rbx
   140001aec:	e8 bf e1 d8 00       	call   140d8fcb0 <dormtr_>
   140001af1:	4c 89 64 24 28       	mov    QWORD PTR [rsp+0x28],r12
   140001af6:	49 89 f9             	mov    r9,rdi
   140001af9:	49 89 d8             	mov    r8,rbx
   140001afc:	48 8b 84 24 30 01 00 	mov    rax,QWORD PTR [rsp+0x130]
   140001b03:	00 
   140001b04:	48 89 5c 24 20       	mov    QWORD PTR [rsp+0x20],rbx
   140001b09:	48 89 da             	mov    rdx,rbx
   140001b0c:	48 8d 0d 8a 26 22 01 	lea    rcx,[rip+0x122268a]        # 14122419d <.rdata+0x3d>
   140001b13:	48 c7 44 24 38 01 00 	mov    QWORD PTR [rsp+0x38],0x1
   140001b1a:	00 00 
   140001b1c:	48 89 44 24 30       	mov    QWORD PTR [rsp+0x30],rax
   140001b21:	e8 9a 0b 00 00       	call   1400026c0 <dlacpy_>
   140001b26:	e9 2d fe ff ff       	jmp    140001958 <dsyevd_+0x508>
   140001b2b:	0f 1f 44 00 00       	nop    DWORD PTR [rax+rax*1+0x0]
   140001b30:	4c 8b 84 24 38 01 00 	mov    r8,QWORD PTR [rsp+0x138]
   140001b37:	00 
   140001b38:	48 8d 94 24 b8 00 00 	lea    rdx,[rsp+0xb8]
   140001b3f:	00 
   140001b40:	48 89 d9             	mov    rcx,rbx
   140001b43:	4c 8d 0d 22 26 22 01 	lea    r9,[rip+0x1222622]        # 14122416c <.rdata+0xc>
   140001b4a:	f2 0f 10 05 4e 26 22 	movsd  xmm0,QWORD PTR [rip+0x122264e]        # 1412241a0 <.rdata+0x40>
   140001b51:	01 
   140001b52:	f2 0f 5e 84 24 b0 00 	divsd  xmm0,QWORD PTR [rsp+0xb0]
   140001b59:	00 00 
   140001b5b:	f2 0f 11 84 24 b8 00 	movsd  QWORD PTR [rsp+0xb8],xmm0
   140001b62:	00 00 
   140001b64:	e8 37 5c 00 00       	call   1400077a0 <dscal_>
   140001b69:	e9 f4 fd ff ff       	jmp    140001962 <dsyevd_+0x512>
   140001b6e:	90                   	nop
   140001b6f:	90                   	nop
   140001b70:	66 2e 0f 1f 84 00 00 	cs nop WORD PTR [rax+rax*1+0x0]
   140001b77:	00 00 00 
   140001b7a:	66 0f 1f 44 00 00    	nop    WORD PTR [rax+rax*1+0x0]

00000001400031e0 <dstedc_>:
   1400031e0:	41 57                	push   r15
   1400031e2:	41 56                	push   r14
   1400031e4:	41 55                	push   r13
   1400031e6:	41 54                	push   r12
   1400031e8:	55                   	push   rbp
   1400031e9:	57                   	push   rdi
   1400031ea:	56                   	push   rsi
   1400031eb:	53                   	push   rbx
   1400031ec:	48 81 ec 08 01 00 00 	sub    rsp,0x108
   1400031f3:	0f 11 b4 24 f0 00 00 	movups XMMWORD PTR [rsp+0xf0],xmm6
   1400031fa:	00 
   1400031fb:	41 bc 01 00 00 00    	mov    r12d,0x1
   140003201:	48 8b 84 24 78 01 00 	mov    rax,QWORD PTR [rsp+0x178]
   140003208:	00 
   140003209:	48 8b ac 24 a0 01 00 	mov    rbp,QWORD PTR [rsp+0x1a0]
   140003210:	00 
   140003211:	8b 00                	mov    eax,DWORD PTR [rax]
   140003213:	c7 45 00 00 00 00 00 	mov    DWORD PTR [rbp+0x0],0x0
   14000321a:	89 84 24 8c 00 00 00 	mov    DWORD PTR [rsp+0x8c],eax
   140003221:	49 89 cd             	mov    r13,rcx
   140003224:	48 89 d7             	mov    rdi,rdx
   140003227:	4c 89 c3             	mov    rbx,r8
   14000322a:	48 8b 84 24 88 01 00 	mov    rax,QWORD PTR [rsp+0x188]
   140003231:	00 
   140003232:	4c 89 ce             	mov    rsi,r9
   140003235:	83 38 ff             	cmp    DWORD PTR [rax],0xffffffff
   140003238:	74 0f                	je     140003249 <dstedc_+0x69>
   14000323a:	48 8b 84 24 98 01 00 	mov    rax,QWORD PTR [rsp+0x198]
   140003241:	00 
   140003242:	83 38 ff             	cmp    DWORD PTR [rax],0xffffffff
   140003245:	41 0f 94 c4          	sete   r12b
   140003249:	41 b9 01 00 00 00    	mov    r9d,0x1
   14000324f:	4c 89 e9             	mov    rcx,r13
   140003252:	41 83 e4 01          	and    r12d,0x1
   140003256:	45 31 f6             	xor    r14d,r14d
   140003259:	41 b8 01 00 00 00    	mov    r8d,0x1
   14000325f:	48 8d 15 ea 0f 22 01 	lea    rdx,[rip+0x1220fea]        # 141224250 <.rdata>
   140003266:	e8 05 2f 01 00       	call   140016170 <lsame_>
   14000326b:	85 c0                	test   eax,eax
   14000326d:	0f 84 6d 01 00 00    	je     1400033e0 <dstedc_+0x200>
   140003273:	8b 07                	mov    eax,DWORD PTR [rdi]
   140003275:	44 89 b4 24 d8 00 00 	mov    DWORD PTR [rsp+0xd8],r14d
   14000327c:	00 
   14000327d:	85 c0                	test   eax,eax
   14000327f:	78 2f                	js     1400032b0 <dstedc_+0xd0>
   140003281:	48 8b 8c 24 78 01 00 	mov    rcx,QWORD PTR [rsp+0x178]
   140003288:	00 
   140003289:	8b 11                	mov    edx,DWORD PTR [rcx]
   14000328b:	85 d2                	test   edx,edx
   14000328d:	7e 13                	jle    1400032a2 <dstedc_+0xc2>
   14000328f:	85 c0                	test   eax,eax
   140003291:	b9 01 00 00 00       	mov    ecx,0x1
   140003296:	0f 4e c1             	cmovle eax,ecx
   140003299:	39 c2                	cmp    edx,eax
   14000329b:	7d 63                	jge    140003300 <dstedc_+0x120>
   14000329d:	45 85 f6             	test   r14d,r14d
   1400032a0:	74 5e                	je     140003300 <dstedc_+0x120>
   1400032a2:	ba fa ff ff ff       	mov    edx,0xfffffffa
   1400032a7:	b8 06 00 00 00       	mov    eax,0x6
   1400032ac:	eb 0c                	jmp    1400032ba <dstedc_+0xda>
   1400032ae:	66 90                	xchg   ax,ax
   1400032b0:	ba fe ff ff ff       	mov    edx,0xfffffffe
   1400032b5:	b8 02 00 00 00       	mov    eax,0x2
   1400032ba:	89 55 00             	mov    DWORD PTR [rbp+0x0],edx
   1400032bd:	4c 8d 15 95 0f 22 01 	lea    r10,[rip+0x1220f95]        # 141224259 <.rdata+0x9>
   1400032c4:	41 b8 06 00 00 00    	mov    r8d,0x6
   1400032ca:	48 8d 94 24 e8 00 00 	lea    rdx,[rsp+0xe8]
   1400032d1:	00 
   1400032d2:	4c 89 d1             	mov    rcx,r10
   1400032d5:	89 84 24 e8 00 00 00 	mov    DWORD PTR [rsp+0xe8],eax
   1400032dc:	e8 1f 0e 01 00       	call   140014100 <xerbla_>
   1400032e1:	90                   	nop
   1400032e2:	0f 10 b4 24 f0 00 00 	movups xmm6,XMMWORD PTR [rsp+0xf0]
   1400032e9:	00 
   1400032ea:	48 81 c4 08 01 00 00 	add    rsp,0x108
   1400032f1:	5b                   	pop    rbx
   1400032f2:	5e                   	pop    rsi
   1400032f3:	5f                   	pop    rdi
   1400032f4:	5d                   	pop    rbp
   1400032f5:	41 5c                	pop    r12
   1400032f7:	41 5d                	pop    r13
   1400032f9:	41 5e                	pop    r14
   1400032fb:	41 5f                	pop    r15
   1400032fd:	c3                   	ret
   1400032fe:	66 90                	xchg   ax,ax
   140003300:	8b 45 00             	mov    eax,DWORD PTR [rbp+0x0]
   140003303:	85 c0                	test   eax,eax
   140003305:	0f 85 19 0c 00 00    	jne    140003f24 <dstedc_+0xd44>
   14000330b:	48 8d 05 42 0f 22 01 	lea    rax,[rip+0x1220f42]        # 141224254 <.rdata+0x4>
   140003312:	4c 8d 15 40 0f 22 01 	lea    r10,[rip+0x1220f40]        # 141224259 <.rdata+0x9>
   140003319:	48 c7 44 24 40 01 00 	mov    QWORD PTR [rsp+0x40],0x1
   140003320:	00 00 
   140003322:	48 c7 44 24 38 06 00 	mov    QWORD PTR [rsp+0x38],0x6
   140003329:	00 00 
   14000332b:	4c 89 d2             	mov    rdx,r10
   14000332e:	49 89 c1             	mov    r9,rax
   140003331:	4c 8d 05 20 0f 22 01 	lea    r8,[rip+0x1220f20]        # 141224258 <.rdata+0x8>
   140003338:	48 89 44 24 30       	mov    QWORD PTR [rsp+0x30],rax
   14000333d:	48 8d 0d 1c 0f 22 01 	lea    rcx,[rip+0x1220f1c]        # 141224260 <.rdata+0x10>
   140003344:	48 89 44 24 28       	mov    QWORD PTR [rsp+0x28],rax
   140003349:	48 89 44 24 20       	mov    QWORD PTR [rsp+0x20],rax
   14000334e:	4c 89 94 24 98 00 00 	mov    QWORD PTR [rsp+0x98],r10
   140003355:	00 
   140003356:	e8 65 35 00 00       	call   1400068c0 <ilaenv_>
   14000335b:	8b 17                	mov    edx,DWORD PTR [rdi]
   14000335d:	4c 8b 94 24 98 00 00 	mov    r10,QWORD PTR [rsp+0x98]
   140003364:	00 
   140003365:	89 84 24 90 00 00 00 	mov    DWORD PTR [rsp+0x90],eax
   14000336c:	83 fa 01             	cmp    edx,0x1
   14000336f:	7e 09                	jle    14000337a <dstedc_+0x19a>
   140003371:	45 85 f6             	test   r14d,r14d
   140003374:	0f 85 e6 00 00 00    	jne    140003460 <dstedc_+0x280>
   14000337a:	f2 0f 10 0d 16 0f 22 	movsd  xmm1,QWORD PTR [rip+0x1220f16]        # 141224298 <.rdata+0x48>
   140003381:	01 
   140003382:	b8 01 00 00 00       	mov    eax,0x1
   140003387:	41 bb 01 00 00 00    	mov    r11d,0x1
   14000338d:	48 8b 8c 24 80 01 00 	mov    rcx,QWORD PTR [rsp+0x180]
   140003394:	00 
   140003395:	f2 0f 11 09          	movsd  QWORD PTR [rcx],xmm1
   140003399:	48 8b 8c 24 90 01 00 	mov    rcx,QWORD PTR [rsp+0x190]
   1400033a0:	00 
   1400033a1:	44 89 19             	mov    DWORD PTR [rcx],r11d
   1400033a4:	48 8b 8c 24 88 01 00 	mov    rcx,QWORD PTR [rsp+0x188]
   1400033ab:	00 
   1400033ac:	39 01                	cmp    DWORD PTR [rcx],eax
   1400033ae:	0f 8c 8c 00 00 00    	jl     140003440 <dstedc_+0x260>
   1400033b4:	48 8b 84 24 98 01 00 	mov    rax,QWORD PTR [rsp+0x198]
   1400033bb:	00 
   1400033bc:	44 39 18             	cmp    DWORD PTR [rax],r11d
   1400033bf:	0f 8d 2b 01 00 00    	jge    1400034f0 <dstedc_+0x310>
   1400033c5:	45 85 e4             	test   r12d,r12d
   1400033c8:	0f 85 52 02 00 00    	jne    140003620 <dstedc_+0x440>
   1400033ce:	c7 45 00 f6 ff ff ff 	mov    DWORD PTR [rbp+0x0],0xfffffff6
   1400033d5:	b8 0a 00 00 00       	mov    eax,0xa
   1400033da:	e9 e5 fe ff ff       	jmp    1400032c4 <dstedc_+0xe4>
   1400033df:	90                   	nop
   1400033e0:	41 b9 01 00 00 00    	mov    r9d,0x1
   1400033e6:	41 b8 01 00 00 00    	mov    r8d,0x1
   1400033ec:	48 8d 15 5e 0e 22 01 	lea    rdx,[rip+0x1220e5e]        # 141224251 <.rdata+0x1>
   1400033f3:	4c 89 e9             	mov    rcx,r13
   1400033f6:	e8 75 2d 01 00       	call   140016170 <lsame_>
   1400033fb:	41 be 01 00 00 00    	mov    r14d,0x1
   140003401:	85 c0                	test   eax,eax
   140003403:	0f 85 6a fe ff ff    	jne    140003273 <dstedc_+0x93>
   140003409:	41 b9 01 00 00 00    	mov    r9d,0x1
   14000340f:	41 b8 01 00 00 00    	mov    r8d,0x1
   140003415:	48 8d 15 36 0e 22 01 	lea    rdx,[rip+0x1220e36]        # 141224252 <.rdata+0x2>
   14000341c:	4c 89 e9             	mov    rcx,r13
   14000341f:	e8 4c 2d 01 00       	call   140016170 <lsame_>
   140003424:	85 c0                	test   eax,eax
   140003426:	0f 85 d1 02 00 00    	jne    1400036fd <dstedc_+0x51d>
   14000342c:	ba ff ff ff ff       	mov    edx,0xffffffff
   140003431:	b8 01 00 00 00       	mov    eax,0x1
   140003436:	e9 7f fe ff ff       	jmp    1400032ba <dstedc_+0xda>
   14000343b:	0f 1f 44 00 00       	nop    DWORD PTR [rax+rax*1+0x0]
   140003440:	45 85 e4             	test   r12d,r12d
   140003443:	0f 85 d7 01 00 00    	jne    140003620 <dstedc_+0x440>
   140003449:	c7 45 00 f8 ff ff ff 	mov    DWORD PTR [rbp+0x0],0xfffffff8
   140003450:	b8 08 00 00 00       	mov    eax,0x8
   140003455:	e9 6a fe ff ff       	jmp    1400032c4 <dstedc_+0xe4>
   14000345a:	66 0f 1f 44 00 00    	nop    WORD PTR [rax+rax*1+0x0]
   140003460:	39 c2                	cmp    edx,eax
   140003462:	0f 8e a0 02 00 00    	jle    140003708 <dstedc_+0x528>
   140003468:	66 0f ef c0          	pxor   xmm0,xmm0
   14000346c:	4c 89 94 24 a0 00 00 	mov    QWORD PTR [rsp+0xa0],r10
   140003473:	00 
   140003474:	89 94 24 98 00 00 00 	mov    DWORD PTR [rsp+0x98],edx
   14000347b:	f2 0f 2a c2          	cvtsi2sd xmm0,edx
   14000347f:	e8 64 e5 20 01       	call   1412119e8 <log>
   140003484:	f2 0f 5e 05 14 0e 22 	divsd  xmm0,QWORD PTR [rip+0x1220e14]        # 1412242a0 <.rdata+0x50>
   14000348b:	01 
   14000348c:	f2 0f 2c c0          	cvttsd2si eax,xmm0
   140003490:	8b 94 24 98 00 00 00 	mov    edx,DWORD PTR [rsp+0x98]
   140003497:	4c 8b 94 24 a0 00 00 	mov    r10,QWORD PTR [rsp+0xa0]
   14000349e:	00 
   14000349f:	83 f8 1f             	cmp    eax,0x1f
   1400034a2:	8d 48 01             	lea    ecx,[rax+0x1]
   1400034a5:	0f 87 9b 09 00 00    	ja     140003e46 <dstedc_+0xc66>
   1400034ab:	41 b8 01 00 00 00    	mov    r8d,0x1
   1400034b1:	89 c1                	mov    ecx,eax
   1400034b3:	45 89 c7             	mov    r15d,r8d
   1400034b6:	41 d3 e7             	shl    r15d,cl
   1400034b9:	44 39 fa             	cmp    edx,r15d
   1400034bc:	0f 8f 6e 09 00 00    	jg     140003e30 <dstedc_+0xc50>
   1400034c2:	41 83 fe 01          	cmp    r14d,0x1
   1400034c6:	0f 84 82 09 00 00    	je     140003e4e <dstedc_+0xc6e>
   1400034cc:	89 d0                	mov    eax,edx
   1400034ce:	8d 0c 95 00 00 00 00 	lea    ecx,[rdx*4+0x0]
   1400034d5:	66 0f ef c9          	pxor   xmm1,xmm1
   1400034d9:	0f af c2             	imul   eax,edx
   1400034dc:	44 8d 5c 0a 03       	lea    r11d,[rdx+rcx*1+0x3]
   1400034e1:	8d 44 01 01          	lea    eax,[rcx+rax*1+0x1]
   1400034e5:	f2 0f 2a c8          	cvtsi2sd xmm1,eax
   1400034e9:	e9 9f fe ff ff       	jmp    14000338d <dstedc_+0x1ad>
   1400034ee:	66 90                	xchg   ax,ax
   1400034f0:	8b 45 00             	mov    eax,DWORD PTR [rbp+0x0]
   1400034f3:	85 c0                	test   eax,eax
   1400034f5:	0f 85 30 01 00 00    	jne    14000362b <dstedc_+0x44b>
   1400034fb:	45 85 e4             	test   r12d,r12d
   1400034fe:	0f 85 de fd ff ff    	jne    1400032e2 <dstedc_+0x102>
   140003504:	85 d2                	test   edx,edx
   140003506:	0f 84 d6 fd ff ff    	je     1400032e2 <dstedc_+0x102>
   14000350c:	83 fa 01             	cmp    edx,0x1
   14000350f:	0f 84 5b 01 00 00    	je     140003670 <dstedc_+0x490>
   140003515:	45 85 f6             	test   r14d,r14d
   140003518:	0f 84 1a 01 00 00    	je     140003638 <dstedc_+0x458>
   14000351e:	3b 94 24 90 00 00 00 	cmp    edx,DWORD PTR [rsp+0x90]
   140003525:	0f 8e 65 01 00 00    	jle    140003690 <dstedc_+0x4b0>
   14000352b:	41 83 fe 01          	cmp    r14d,0x1
   14000352f:	0f 84 ea 01 00 00    	je     14000371f <dstedc_+0x53f>
   140003535:	48 8b 84 24 78 01 00 	mov    rax,QWORD PTR [rsp+0x178]
   14000353c:	00 
   14000353d:	4c 8d 0d 24 0d 22 01 	lea    r9,[rip+0x1220d24]        # 141224268 <.rdata+0x18>
   140003544:	49 89 f8             	mov    r8,rdi
   140003547:	48 89 fa             	mov    rdx,rdi
   14000354a:	48 c7 44 24 38 04 00 	mov    QWORD PTR [rsp+0x38],0x4
   140003551:	00 00 
   140003553:	48 8d 0d 16 0d 22 01 	lea    rcx,[rip+0x1220d16]        # 141224270 <.rdata+0x20>
   14000355a:	41 bc 01 00 00 00    	mov    r12d,0x1
   140003560:	48 89 44 24 30       	mov    QWORD PTR [rsp+0x30],rax
   140003565:	48 8b 84 24 70 01 00 	mov    rax,QWORD PTR [rsp+0x170]
   14000356c:	00 
   14000356d:	44 89 9c 24 98 00 00 	mov    DWORD PTR [rsp+0x98],r11d
   140003574:	00 
   140003575:	48 89 44 24 28       	mov    QWORD PTR [rsp+0x28],rax
   14000357a:	48 8d 05 f7 0c 22 01 	lea    rax,[rip+0x1220cf7]        # 141224278 <.rdata+0x28>
   140003581:	48 89 44 24 20       	mov    QWORD PTR [rsp+0x20],rax
   140003586:	f2 0f 11 8c 24 a0 00 	movsd  QWORD PTR [rsp+0xa0],xmm1
   14000358d:	00 00 
   14000358f:	e8 ec 25 d9 00       	call   140d95b80 <dlaset_>
   140003594:	44 8b 9c 24 98 00 00 	mov    r11d,DWORD PTR [rsp+0x98]
   14000359b:	00 
   14000359c:	f2 0f 10 8c 24 a0 00 	movsd  xmm1,QWORD PTR [rsp+0xa0]
   1400035a3:	00 00 
   1400035a5:	49 89 f1             	mov    r9,rsi
   1400035a8:	49 89 d8             	mov    r8,rbx
   1400035ab:	48 8d 0d ce 0c 22 01 	lea    rcx,[rip+0x1220cce]        # 141224280 <.rdata+0x30>
   1400035b2:	48 89 fa             	mov    rdx,rdi
   1400035b5:	48 c7 44 24 20 01 00 	mov    QWORD PTR [rsp+0x20],0x1
   1400035bc:	00 00 
   1400035be:	44 89 9c 24 98 00 00 	mov    DWORD PTR [rsp+0x98],r11d
   1400035c5:	00 
   1400035c6:	f2 0f 11 8c 24 a0 00 	movsd  QWORD PTR [rsp+0xa0],xmm1
   1400035cd:	00 00 
   1400035cf:	e8 0c 20 d9 00       	call   140d955e0 <dlanst_>
   1400035d4:	44 8b 9c 24 98 00 00 	mov    r11d,DWORD PTR [rsp+0x98]
   1400035db:	00 
   1400035dc:	f2 0f 10 8c 24 a0 00 	movsd  xmm1,QWORD PTR [rsp+0xa0]
   1400035e3:	00 00 
   1400035e5:	66 0f 28 d0          	movapd xmm2,xmm0
   1400035e9:	66 0f ef c0          	pxor   xmm0,xmm0
   1400035ed:	66 0f 2e d0          	ucomisd xmm2,xmm0
   1400035f1:	0f 8a 34 01 00 00    	jp     14000372b <dstedc_+0x54b>
   1400035f7:	0f 85 2e 01 00 00    	jne    14000372b <dstedc_+0x54b>
   1400035fd:	48 8b 84 24 80 01 00 	mov    rax,QWORD PTR [rsp+0x180]
   140003604:	00 
   140003605:	f2 0f 11 08          	movsd  QWORD PTR [rax],xmm1
   140003609:	48 8b 84 24 90 01 00 	mov    rax,QWORD PTR [rsp+0x190]
   140003610:	00 
   140003611:	44 89 18             	mov    DWORD PTR [rax],r11d
   140003614:	e9 c9 fc ff ff       	jmp    1400032e2 <dstedc_+0x102>
   140003619:	0f 1f 80 00 00 00 00 	nop    DWORD PTR [rax+0x0]
   140003620:	8b 45 00             	mov    eax,DWORD PTR [rbp+0x0]
   140003623:	85 c0                	test   eax,eax
   140003625:	0f 84 b7 fc ff ff    	je     1400032e2 <dstedc_+0x102>
   14000362b:	f7 d8                	neg    eax
   14000362d:	e9 92 fc ff ff       	jmp    1400032c4 <dstedc_+0xe4>
   140003632:	66 0f 1f 44 00 00    	nop    WORD PTR [rax+rax*1+0x0]
   140003638:	49 89 e9             	mov    r9,rbp
   14000363b:	49 89 f0             	mov    r8,rsi
   14000363e:	48 89 da             	mov    rdx,rbx
   140003641:	48 89 f9             	mov    rcx,rdi
   140003644:	44 89 9c 24 8c 00 00 	mov    DWORD PTR [rsp+0x8c],r11d
   14000364b:	00 
   14000364c:	f2 0f 11 8c 24 90 00 	movsd  QWORD PTR [rsp+0x90],xmm1
   140003653:	00 00 
   140003655:	e8 e6 21 00 00       	call   140005840 <dsterf_>
   14000365a:	44 8b 9c 24 8c 00 00 	mov    r11d,DWORD PTR [rsp+0x8c]
   140003661:	00 
   140003662:	f2 0f 10 8c 24 90 00 	movsd  xmm1,QWORD PTR [rsp+0x90]
   140003669:	00 00 
   14000366b:	eb 90                	jmp    1400035fd <dstedc_+0x41d>
   14000366d:	0f 1f 00             	nop    DWORD PTR [rax]
   140003670:	45 85 f6             	test   r14d,r14d
   140003673:	0f 84 69 fc ff ff    	je     1400032e2 <dstedc_+0x102>
   140003679:	48 8b 84 24 70 01 00 	mov    rax,QWORD PTR [rsp+0x170]
   140003680:	00 
   140003681:	48 8b 3d 10 0c 22 01 	mov    rdi,QWORD PTR [rip+0x1220c10]        # 141224298 <.rdata+0x48>
   140003688:	48 89 38             	mov    QWORD PTR [rax],rdi
   14000368b:	e9 52 fc ff ff       	jmp    1400032e2 <dstedc_+0x102>
   140003690:	48 89 6c 24 38       	mov    QWORD PTR [rsp+0x38],rbp
   140003695:	49 89 f1             	mov    r9,rsi
   140003698:	49 89 d8             	mov    r8,rbx
   14000369b:	48 89 fa             	mov    rdx,rdi
   14000369e:	48 8b 84 24 80 01 00 	mov    rax,QWORD PTR [rsp+0x180]
   1400036a5:	00 
   1400036a6:	4c 89 e9             	mov    rcx,r13
   1400036a9:	48 c7 44 24 40 01 00 	mov    QWORD PTR [rsp+0x40],0x1
   1400036b0:	00 00 
   1400036b2:	44 89 9c 24 8c 00 00 	mov    DWORD PTR [rsp+0x8c],r11d
   1400036b9:	00 
   1400036ba:	48 89 44 24 30       	mov    QWORD PTR [rsp+0x30],rax
   1400036bf:	48 8b 84 24 78 01 00 	mov    rax,QWORD PTR [rsp+0x178]
   1400036c6:	00 
   1400036c7:	f2 0f 11 8c 24 90 00 	movsd  QWORD PTR [rsp+0x90],xmm1
   1400036ce:	00 00 
   1400036d0:	48 89 44 24 28       	mov    QWORD PTR [rsp+0x28],rax
   1400036d5:	48 8b 84 24 70 01 00 	mov    rax,QWORD PTR [rsp+0x170]
   1400036dc:	00 
   1400036dd:	48 89 44 24 20       	mov    QWORD PTR [rsp+0x20],rax
   1400036e2:	e8 59 08 00 00       	call   140003f40 <dsteqr_>
   1400036e7:	44 8b 9c 24 8c 00 00 	mov    r11d,DWORD PTR [rsp+0x8c]
   1400036ee:	00 
   1400036ef:	f2 0f 10 8c 24 90 00 	movsd  xmm1,QWORD PTR [rsp+0x90]
   1400036f6:	00 00 
   1400036f8:	e9 00 ff ff ff       	jmp    1400035fd <dstedc_+0x41d>
   1400036fd:	41 be 02 00 00 00    	mov    r14d,0x2
   140003703:	e9 6b fb ff ff       	jmp    140003273 <dstedc_+0x93>
   140003708:	8d 44 12 fe          	lea    eax,[rdx+rdx*1-0x2]
   14000370c:	66 0f ef c9          	pxor   xmm1,xmm1
   140003710:	41 bb 01 00 00 00    	mov    r11d,0x1
   140003716:	f2 0f 2a c8          	cvtsi2sd xmm1,eax
   14000371a:	e9 6e fc ff ff       	jmp    14000338d <dstedc_+0x1ad>
   14000371f:	0f af d2             	imul   edx,edx
   140003722:	44 8d 62 01          	lea    r12d,[rdx+0x1]
   140003726:	e9 7a fe ff ff       	jmp    1400035a5 <dstedc_+0x3c5>
   14000372b:	ba 07 00 00 00       	mov    edx,0x7
   140003730:	48 8d 0d 4a 0b 22 01 	lea    rcx,[rip+0x1220b4a]        # 141224281 <.rdata+0x31>
   140003737:	44 89 9c 24 98 00 00 	mov    DWORD PTR [rsp+0x98],r11d
   14000373e:	00 
   14000373f:	f2 0f 11 8c 24 a0 00 	movsd  QWORD PTR [rsp+0xa0],xmm1
   140003746:	00 00 
   140003748:	e8 93 2f 00 00       	call   1400066e0 <dlamch_>
   14000374d:	44 8b 2f             	mov    r13d,DWORD PTR [rdi]
   140003750:	44 8b 9c 24 98 00 00 	mov    r11d,DWORD PTR [rsp+0x98]
   140003757:	00 
   140003758:	f2 0f 10 8c 24 a0 00 	movsd  xmm1,QWORD PTR [rsp+0xa0]
   14000375f:	00 00 
   140003761:	66 0f 28 d8          	movapd xmm3,xmm0
   140003765:	45 85 ed             	test   r13d,r13d
   140003768:	0f 8e 8f fe ff ff    	jle    1400035fd <dstedc_+0x41d>
   14000376e:	48 63 94 24 8c 00 00 	movsxd rdx,DWORD PTR [rsp+0x8c]
   140003775:	00 
   140003776:	31 c0                	xor    eax,eax
   140003778:	48 8b 8c 24 80 01 00 	mov    rcx,QWORD PTR [rsp+0x180]
   14000377f:	00 
   140003780:	44 89 9c 24 cc 00 00 	mov    DWORD PTR [rsp+0xcc],r11d
   140003787:	00 
   140003788:	44 89 b4 24 8c 00 00 	mov    DWORD PTR [rsp+0x8c],r14d
   14000378f:	00 
   140003790:	41 ba 01 00 00 00    	mov    r10d,0x1
   140003796:	66 0f 28 f1          	movapd xmm6,xmm1
   14000379a:	48 85 d2             	test   rdx,rdx
   14000379d:	48 0f 48 d0          	cmovs  rdx,rax
   1400037a1:	48 89 d0             	mov    rax,rdx
   1400037a4:	48 89 94 24 a8 00 00 	mov    QWORD PTR [rsp+0xa8],rdx
   1400037ab:	00 
   1400037ac:	48 f7 d0             	not    rax
   1400037af:	48 89 84 24 a0 00 00 	mov    QWORD PTR [rsp+0xa0],rax
   1400037b6:	00 
   1400037b7:	41 8d 44 24 ff       	lea    eax,[r12-0x1]
   1400037bc:	48 8d 04 c1          	lea    rax,[rcx+rax*8]
   1400037c0:	48 89 84 24 c0 00 00 	mov    QWORD PTR [rsp+0xc0],rax
   1400037c7:	00 
   1400037c8:	0f 1f 84 00 00 00 00 	nop    DWORD PTR [rax+rax*1+0x0]
   1400037cf:	00 
   1400037d0:	49 63 c2             	movsxd rax,r10d
   1400037d3:	48 89 c2             	mov    rdx,rax
   1400037d6:	eb 4b                	jmp    140003823 <dstedc_+0x643>
   1400037d8:	0f 1f 84 00 00 00 00 	nop    DWORD PTR [rax+rax*1+0x0]
   1400037df:	00 
   1400037e0:	f2 0f 10 44 d3 f8    	movsd  xmm0,QWORD PTR [rbx+rdx*8-0x8]
   1400037e6:	66 0f 54 05 c2 0a 22 	andpd  xmm0,XMMWORD PTR [rip+0x1220ac2]        # 1412242b0 <.rdata+0x60>
   1400037ed:	01 
   1400037ee:	f2 0f 10 0c d3       	movsd  xmm1,QWORD PTR [rbx+rdx*8]
   1400037f3:	66 0f 54 0d b5 0a 22 	andpd  xmm1,XMMWORD PTR [rip+0x1220ab5]        # 1412242b0 <.rdata+0x60>
   1400037fa:	01 
   1400037fb:	f2 0f 51 c0          	sqrtsd xmm0,xmm0
   1400037ff:	f2 0f 10 54 d6 f8    	movsd  xmm2,QWORD PTR [rsi+rdx*8-0x8]
   140003805:	66 0f 54 15 a3 0a 22 	andpd  xmm2,XMMWORD PTR [rip+0x1220aa3]        # 1412242b0 <.rdata+0x60>
   14000380c:	01 
   14000380d:	f2 0f 51 c9          	sqrtsd xmm1,xmm1
   140003811:	f2 0f 59 c3          	mulsd  xmm0,xmm3
   140003815:	f2 0f 59 c1          	mulsd  xmm0,xmm1
   140003819:	66 0f 2f d0          	comisd xmm2,xmm0
   14000381d:	76 09                	jbe    140003828 <dstedc_+0x648>
   14000381f:	48 83 c2 01          	add    rdx,0x1
   140003823:	41 39 d5             	cmp    r13d,edx
   140003826:	7f b8                	jg     1400037e0 <dstedc_+0x600>
   140003828:	89 d1                	mov    ecx,edx
   14000382a:	41 89 d6             	mov    r14d,edx
   14000382d:	44 29 d1             	sub    ecx,r10d
   140003830:	83 c1 01             	add    ecx,0x1
   140003833:	89 8c 24 dc 00 00 00 	mov    DWORD PTR [rsp+0xdc],ecx
   14000383a:	83 f9 01             	cmp    ecx,0x1
   14000383d:	0f 84 85 01 00 00    	je     1400039c8 <dstedc_+0x7e8>
   140003843:	3b 8c 24 90 00 00 00 	cmp    ecx,DWORD PTR [rsp+0x90]
   14000384a:	0f 8f 88 01 00 00    	jg     1400039d8 <dstedc_+0x7f8>
   140003850:	83 bc 24 8c 00 00 00 	cmp    DWORD PTR [rsp+0x8c],0x1
   140003857:	01 
   140003858:	0f 84 75 04 00 00    	je     140003cd3 <dstedc_+0xaf3>
   14000385e:	83 bc 24 8c 00 00 00 	cmp    DWORD PTR [rsp+0x8c],0x2
   140003865:	02 
   140003866:	0f 84 cc 03 00 00    	je     140003c38 <dstedc_+0xa58>
   14000386c:	41 8d 42 ff          	lea    eax,[r10-0x1]
   140003870:	48 8d 8c 24 dc 00 00 	lea    rcx,[rsp+0xdc]
   140003877:	00 
   140003878:	49 89 e9             	mov    r9,rbp
   14000387b:	44 89 94 24 98 00 00 	mov    DWORD PTR [rsp+0x98],r10d
   140003882:	00 
   140003883:	f2 0f 11 9c 24 b0 00 	movsd  QWORD PTR [rsp+0xb0],xmm3
   14000388a:	00 00 
   14000388c:	48 98                	cdqe
   14000388e:	48 c1 e0 03          	shl    rax,0x3
   140003892:	48 8d 14 03          	lea    rdx,[rbx+rax*1]
   140003896:	4c 8d 04 06          	lea    r8,[rsi+rax*1]
   14000389a:	e8 a1 1f 00 00       	call   140005840 <dsterf_>
   14000389f:	44 8b 94 24 98 00 00 	mov    r10d,DWORD PTR [rsp+0x98]
   1400038a6:	00 
   1400038a7:	f2 0f 10 9c 24 b0 00 	movsd  xmm3,QWORD PTR [rsp+0xb0]
   1400038ae:	00 00 
   1400038b0:	8b 55 00             	mov    edx,DWORD PTR [rbp+0x0]
   1400038b3:	85 d2                	test   edx,edx
   1400038b5:	0f 85 cf 05 00 00    	jne    140003e8a <dstedc_+0xcaa>
   1400038bb:	44 8b 2f             	mov    r13d,DWORD PTR [rdi]
   1400038be:	45 8d 56 01          	lea    r10d,[r14+0x1]
   1400038c2:	45 39 d5             	cmp    r13d,r10d
   1400038c5:	0f 8d 05 ff ff ff    	jge    1400037d0 <dstedc_+0x5f0>
   1400038cb:	8b 84 24 8c 00 00 00 	mov    eax,DWORD PTR [rsp+0x8c]
   1400038d2:	44 8b 9c 24 cc 00 00 	mov    r11d,DWORD PTR [rsp+0xcc]
   1400038d9:	00 
   1400038da:	66 0f 28 ce          	movapd xmm1,xmm6
   1400038de:	48 8b 94 24 a8 00 00 	mov    rdx,QWORD PTR [rsp+0xa8]
   1400038e5:	00 
   1400038e6:	85 c0                	test   eax,eax
   1400038e8:	0f 84 bc 05 00 00    	je     140003eaa <dstedc_+0xcca>
   1400038ee:	41 83 fd 01          	cmp    r13d,0x1
   1400038f2:	0f 8e 05 fd ff ff    	jle    1400035fd <dstedc_+0x41d>
   1400038f8:	45 89 e8             	mov    r8d,r13d
   1400038fb:	be 02 00 00 00       	mov    esi,0x2
   140003900:	45 89 df             	mov    r15d,r11d
   140003903:	49 89 d6             	mov    r14,rdx
   140003906:	4c 8b a4 24 70 01 00 	mov    r12,QWORD PTR [rsp+0x170]
   14000390d:	00 
   14000390e:	48 8d 2c d5 00 00 00 	lea    rbp,[rdx*8+0x0]
   140003915:	00 
   140003916:	66 2e 0f 1f 84 00 00 	cs nop WORD PTR [rax+rax*1+0x0]
   14000391d:	00 00 00 
   140003920:	41 39 f0             	cmp    r8d,esi
   140003923:	0f 8c 84 00 00 00    	jl     1400039ad <dstedc_+0x7cd>
   140003929:	f2 0f 10 54 f3 f0    	movsd  xmm2,QWORD PTR [rbx+rsi*8-0x10]
   14000392f:	44 8d 4e ff          	lea    r9d,[rsi-0x1]
   140003933:	48 89 f0             	mov    rax,rsi
   140003936:	44 89 ca             	mov    edx,r9d
   140003939:	66 0f 28 c2          	movapd xmm0,xmm2
   14000393d:	0f 1f 00             	nop    DWORD PTR [rax]
   140003940:	f2 0f 10 4c c3 f8    	movsd  xmm1,QWORD PTR [rbx+rax*8-0x8]
   140003946:	66 0f 2f c1          	comisd xmm0,xmm1
   14000394a:	f2 0f 5d c8          	minsd  xmm1,xmm0
   14000394e:	0f 47 d0             	cmova  edx,eax
   140003951:	48 83 c0 01          	add    rax,0x1
   140003955:	66 0f 28 c1          	movapd xmm0,xmm1
   140003959:	41 39 c0             	cmp    r8d,eax
   14000395c:	7d e2                	jge    140003940 <dstedc_+0x760>
   14000395e:	44 39 ca             	cmp    edx,r9d
   140003961:	74 4a                	je     1400039ad <dstedc_+0x7cd>
   140003963:	48 63 d2             	movsxd rdx,edx
   140003966:	48 8d 0d 1f 09 22 01 	lea    rcx,[rip+0x122091f]        # 14122428c <.rdata+0x3c>
   14000396d:	48 8b 84 24 a0 00 00 	mov    rax,QWORD PTR [rsp+0xa0]
   140003974:	00 
   140003975:	4c 8d 05 10 09 22 01 	lea    r8,[rip+0x1220910]        # 14122428c <.rdata+0x3c>
   14000397c:	f2 0f 11 54 d3 f8    	movsd  QWORD PTR [rbx+rdx*8-0x8],xmm2
   140003982:	49 0f af d6          	imul   rdx,r14
   140003986:	f2 0f 11 4c f3 f0    	movsd  QWORD PTR [rbx+rsi*8-0x10],xmm1
   14000398c:	48 89 4c 24 20       	mov    QWORD PTR [rsp+0x20],rcx
   140003991:	48 8b 8c 24 70 01 00 	mov    rcx,QWORD PTR [rsp+0x170]
   140003998:	00 
   140003999:	48 8d 44 10 01       	lea    rax,[rax+rdx*1+0x1]
   14000399e:	4c 89 e2             	mov    rdx,r12
   1400039a1:	4c 8d 0c c1          	lea    r9,[rcx+rax*8]
   1400039a5:	48 89 f9             	mov    rcx,rdi
   1400039a8:	e8 43 3d 00 00       	call   1400076f0 <dswap_>
   1400039ad:	48 83 c6 01          	add    rsi,0x1
   1400039b1:	41 39 f5             	cmp    r13d,esi
   1400039b4:	0f 8c c4 04 00 00    	jl     140003e7e <dstedc_+0xc9e>
   1400039ba:	44 8b 07             	mov    r8d,DWORD PTR [rdi]
   1400039bd:	49 01 ec             	add    r12,rbp
   1400039c0:	e9 5b ff ff ff       	jmp    140003920 <dstedc_+0x740>
   1400039c5:	0f 1f 00             	nop    DWORD PTR [rax]
   1400039c8:	44 8d 52 01          	lea    r10d,[rdx+0x1]
   1400039cc:	e9 f1 fe ff ff       	jmp    1400038c2 <dstedc_+0x6e2>
   1400039d1:	0f 1f 80 00 00 00 00 	nop    DWORD PTR [rax+0x0]
   1400039d8:	4c 8d 24 c5 f8 ff ff 	lea    r12,[rax*8-0x8]
   1400039df:	ff 
   1400039e0:	4c 8d ac 24 dc 00 00 	lea    r13,[rsp+0xdc]
   1400039e7:	00 
   1400039e8:	48 c7 44 24 20 01 00 	mov    QWORD PTR [rsp+0x20],0x1
   1400039ef:	00 00 
   1400039f1:	4e 8d 3c 26          	lea    r15,[rsi+r12*1]
   1400039f5:	49 01 dc             	add    r12,rbx
   1400039f8:	4c 89 ea             	mov    rdx,r13
   1400039fb:	44 89 94 24 c8 00 00 	mov    DWORD PTR [rsp+0xc8],r10d
   140003a02:	00 
   140003a03:	4d 89 f9             	mov    r9,r15
   140003a06:	4d 89 e0             	mov    r8,r12
   140003a09:	48 8d 0d 70 08 22 01 	lea    rcx,[rip+0x1220870]        # 141224280 <.rdata+0x30>
   140003a10:	f2 0f 11 9c 24 b8 00 	movsd  QWORD PTR [rsp+0xb8],xmm3
   140003a17:	00 00 
   140003a19:	48 89 84 24 b0 00 00 	mov    QWORD PTR [rsp+0xb0],rax
   140003a20:	00 
   140003a21:	e8 ba 1b d9 00       	call   140d955e0 <dlanst_>
   140003a26:	48 8d 0d 5f 08 22 01 	lea    rcx,[rip+0x122085f]        # 14122428c <.rdata+0x3c>
   140003a2d:	48 89 6c 24 48       	mov    QWORD PTR [rsp+0x48],rbp
   140003a32:	48 8d 15 3f 08 22 01 	lea    rdx,[rip+0x122083f]        # 141224278 <.rdata+0x28>
   140003a39:	48 89 4c 24 30       	mov    QWORD PTR [rsp+0x30],rcx
   140003a3e:	48 8d 84 24 e8 00 00 	lea    rax,[rsp+0xe8]
   140003a45:	00 
   140003a46:	4c 8d 05 07 08 22 01 	lea    r8,[rip+0x1220807]        # 141224254 <.rdata+0x4>
   140003a4d:	48 89 54 24 20       	mov    QWORD PTR [rsp+0x20],rdx
   140003a52:	49 89 c1             	mov    r9,rax
   140003a55:	4c 89 c2             	mov    rdx,r8
   140003a58:	48 8d 0d 29 08 22 01 	lea    rcx,[rip+0x1220829]        # 141224288 <.rdata+0x38>
   140003a5f:	48 c7 44 24 50 01 00 	mov    QWORD PTR [rsp+0x50],0x1
   140003a66:	00 00 
   140003a68:	4c 89 6c 24 40       	mov    QWORD PTR [rsp+0x40],r13
   140003a6d:	4c 89 64 24 38       	mov    QWORD PTR [rsp+0x38],r12
   140003a72:	4c 89 6c 24 28       	mov    QWORD PTR [rsp+0x28],r13
   140003a77:	48 89 84 24 98 00 00 	mov    QWORD PTR [rsp+0x98],rax
   140003a7e:	00 
   140003a7f:	f2 0f 11 84 24 e8 00 	movsd  QWORD PTR [rsp+0xe8],xmm0
   140003a86:	00 00 
   140003a88:	e8 13 ee ff ff       	call   1400028a0 <dlascl_>
   140003a8d:	44 8b 9c 24 dc 00 00 	mov    r11d,DWORD PTR [rsp+0xdc]
   140003a94:	00 
   140003a95:	48 89 6c 24 48       	mov    QWORD PTR [rsp+0x48],rbp
   140003a9a:	48 8d 0d eb 07 22 01 	lea    rcx,[rip+0x12207eb]        # 14122428c <.rdata+0x3c>
   140003aa1:	48 89 4c 24 30       	mov    QWORD PTR [rsp+0x30],rcx
   140003aa6:	4c 8d 05 a7 07 22 01 	lea    r8,[rip+0x12207a7]        # 141224254 <.rdata+0x4>
   140003aad:	4c 8b 8c 24 98 00 00 	mov    r9,QWORD PTR [rsp+0x98]
   140003ab4:	00 
   140003ab5:	48 8d 0d cc 07 22 01 	lea    rcx,[rip+0x12207cc]        # 141224288 <.rdata+0x38>
   140003abc:	41 8d 53 ff          	lea    edx,[r11-0x1]
   140003ac0:	4c 89 7c 24 38       	mov    QWORD PTR [rsp+0x38],r15
   140003ac5:	89 94 24 e0 00 00 00 	mov    DWORD PTR [rsp+0xe0],edx
   140003acc:	89 94 24 e4 00 00 00 	mov    DWORD PTR [rsp+0xe4],edx
   140003ad3:	48 8d 94 24 e4 00 00 	lea    rdx,[rsp+0xe4]
   140003ada:	00 
   140003adb:	48 89 54 24 40       	mov    QWORD PTR [rsp+0x40],rdx
   140003ae0:	48 8d 94 24 e0 00 00 	lea    rdx,[rsp+0xe0]
   140003ae7:	00 
   140003ae8:	48 89 54 24 28       	mov    QWORD PTR [rsp+0x28],rdx
   140003aed:	48 8d 15 84 07 22 01 	lea    rdx,[rip+0x1220784]        # 141224278 <.rdata+0x28>
   140003af4:	48 89 54 24 20       	mov    QWORD PTR [rsp+0x20],rdx
   140003af9:	4c 89 c2             	mov    rdx,r8
   140003afc:	48 c7 44 24 50 01 00 	mov    QWORD PTR [rsp+0x50],0x1
   140003b03:	00 00 
   140003b05:	e8 96 ed ff ff       	call   1400028a0 <dlascl_>
   140003b0a:	ba 01 00 00 00       	mov    edx,0x1
   140003b0f:	4d 89 e1             	mov    r9,r12
   140003b12:	4d 89 e8             	mov    r8,r13
   140003b15:	4c 8b 9c 24 90 01 00 	mov    r11,QWORD PTR [rsp+0x190]
   140003b1c:	00 
   140003b1d:	48 8b 84 24 b0 00 00 	mov    rax,QWORD PTR [rsp+0xb0]
   140003b24:	00 
   140003b25:	48 89 6c 24 58       	mov    QWORD PTR [rsp+0x58],rbp
   140003b2a:	48 8d 8c 24 d8 00 00 	lea    rcx,[rsp+0xd8]
   140003b31:	00 
   140003b32:	83 bc 24 8c 00 00 00 	cmp    DWORD PTR [rsp+0x8c],0x1
   140003b39:	01 
   140003b3a:	48 89 7c 24 40       	mov    QWORD PTR [rsp+0x40],rdi
   140003b3f:	4c 89 5c 24 50       	mov    QWORD PTR [rsp+0x50],r11
   140003b44:	4c 8b 9c 24 c0 00 00 	mov    r11,QWORD PTR [rsp+0xc0]
   140003b4b:	00 
   140003b4c:	48 0f 45 d0          	cmovne rdx,rax
   140003b50:	48 0f af 84 24 a8 00 	imul   rax,QWORD PTR [rsp+0xa8]
   140003b57:	00 00 
   140003b59:	4c 89 7c 24 20       	mov    QWORD PTR [rsp+0x20],r15
   140003b5e:	48 03 84 24 a0 00 00 	add    rax,QWORD PTR [rsp+0xa0]
   140003b65:	00 
   140003b66:	4c 89 5c 24 48       	mov    QWORD PTR [rsp+0x48],r11
   140003b6b:	4c 8b 9c 24 80 01 00 	mov    r11,QWORD PTR [rsp+0x180]
   140003b72:	00 
   140003b73:	48 01 d0             	add    rax,rdx
   140003b76:	48 8b 94 24 70 01 00 	mov    rdx,QWORD PTR [rsp+0x170]
   140003b7d:	00 
   140003b7e:	4c 89 5c 24 38       	mov    QWORD PTR [rsp+0x38],r11
   140003b83:	4c 8b 9c 24 78 01 00 	mov    r11,QWORD PTR [rsp+0x178]
   140003b8a:	00 
   140003b8b:	48 8d 04 c2          	lea    rax,[rdx+rax*8]
   140003b8f:	48 89 fa             	mov    rdx,rdi
   140003b92:	48 89 44 24 28       	mov    QWORD PTR [rsp+0x28],rax
   140003b97:	4c 89 5c 24 30       	mov    QWORD PTR [rsp+0x30],r11
   140003b9c:	e8 9f d1 d8 00       	call   140d90d40 <dlaed0_>
   140003ba1:	8b 45 00             	mov    eax,DWORD PTR [rbp+0x0]
   140003ba4:	44 8b 94 24 c8 00 00 	mov    r10d,DWORD PTR [rsp+0xc8]
   140003bab:	00 
   140003bac:	f2 0f 10 9c 24 b8 00 	movsd  xmm3,QWORD PTR [rsp+0xb8]
   140003bb3:	00 00 
   140003bb5:	85 c0                	test   eax,eax
   140003bb7:	0f 85 32 03 00 00    	jne    140003eef <dstedc_+0xd0f>
   140003bbd:	48 8d 05 c8 06 22 01 	lea    rax,[rip+0x12206c8]        # 14122428c <.rdata+0x3c>
   140003bc4:	48 89 6c 24 48       	mov    QWORD PTR [rsp+0x48],rbp
   140003bc9:	4c 8d 05 84 06 22 01 	lea    r8,[rip+0x1220684]        # 141224254 <.rdata+0x4>
   140003bd0:	48 89 44 24 30       	mov    QWORD PTR [rsp+0x30],rax
   140003bd5:	48 8b 84 24 98 00 00 	mov    rax,QWORD PTR [rsp+0x98]
   140003bdc:	00 
   140003bdd:	4c 89 c2             	mov    rdx,r8
   140003be0:	4c 8d 0d 91 06 22 01 	lea    r9,[rip+0x1220691]        # 141224278 <.rdata+0x28>
   140003be7:	48 c7 44 24 50 01 00 	mov    QWORD PTR [rsp+0x50],0x1
   140003bee:	00 00 
   140003bf0:	48 8d 0d 91 06 22 01 	lea    rcx,[rip+0x1220691]        # 141224288 <.rdata+0x38>
   140003bf7:	48 89 44 24 20       	mov    QWORD PTR [rsp+0x20],rax
   140003bfc:	4c 89 6c 24 40       	mov    QWORD PTR [rsp+0x40],r13
   140003c01:	4c 89 64 24 38       	mov    QWORD PTR [rsp+0x38],r12
   140003c06:	4c 89 6c 24 28       	mov    QWORD PTR [rsp+0x28],r13
   140003c0b:	f2 0f 11 9c 24 b0 00 	movsd  QWORD PTR [rsp+0xb0],xmm3
   140003c12:	00 00 
   140003c14:	e8 87 ec ff ff       	call   1400028a0 <dlascl_>
   140003c19:	8b 84 24 d8 00 00 00 	mov    eax,DWORD PTR [rsp+0xd8]
   140003c20:	f2 0f 10 9c 24 b0 00 	movsd  xmm3,QWORD PTR [rsp+0xb0]
   140003c27:	00 00 
   140003c29:	89 84 24 8c 00 00 00 	mov    DWORD PTR [rsp+0x8c],eax
   140003c30:	e9 86 fc ff ff       	jmp    1400038bb <dstedc_+0x6db>
   140003c35:	0f 1f 00             	nop    DWORD PTR [rax]
   140003c38:	4c 8b bc 24 80 01 00 	mov    r15,QWORD PTR [rsp+0x180]
   140003c3f:	00 
   140003c40:	48 89 6c 24 38       	mov    QWORD PTR [rsp+0x38],rbp
   140003c45:	48 8d 0c c5 f8 ff ff 	lea    rcx,[rax*8-0x8]
   140003c4c:	ff 
   140003c4d:	48 8d 94 24 dc 00 00 	lea    rdx,[rsp+0xdc]
   140003c54:	00 
   140003c55:	4c 8b 84 24 a8 00 00 	mov    r8,QWORD PTR [rsp+0xa8]
   140003c5c:	00 
   140003c5d:	4c 8d 0c 0e          	lea    r9,[rsi+rcx*1]
   140003c61:	48 c7 44 24 40 01 00 	mov    QWORD PTR [rsp+0x40],0x1
   140003c68:	00 00 
   140003c6a:	4c 89 7c 24 30       	mov    QWORD PTR [rsp+0x30],r15
   140003c6f:	4c 8b bc 24 78 01 00 	mov    r15,QWORD PTR [rsp+0x178]
   140003c76:	00 
   140003c77:	4c 0f af c0          	imul   r8,rax
   140003c7b:	4c 03 84 24 a0 00 00 	add    r8,QWORD PTR [rsp+0xa0]
   140003c82:	00 
   140003c83:	44 89 94 24 b0 00 00 	mov    DWORD PTR [rsp+0xb0],r10d
   140003c8a:	00 
   140003c8b:	4c 89 7c 24 28       	mov    QWORD PTR [rsp+0x28],r15
   140003c90:	4c 01 c0             	add    rax,r8
   140003c93:	4c 8d 04 0b          	lea    r8,[rbx+rcx*1]
   140003c97:	4c 8b bc 24 70 01 00 	mov    r15,QWORD PTR [rsp+0x170]
   140003c9e:	00 
   140003c9f:	f2 0f 11 9c 24 98 00 	movsd  QWORD PTR [rsp+0x98],xmm3
   140003ca6:	00 00 
   140003ca8:	48 8d 0d a3 05 22 01 	lea    rcx,[rip+0x12205a3]        # 141224252 <.rdata+0x2>
   140003caf:	49 8d 04 c7          	lea    rax,[r15+rax*8]
   140003cb3:	48 89 44 24 20       	mov    QWORD PTR [rsp+0x20],rax
   140003cb8:	e8 83 02 00 00       	call   140003f40 <dsteqr_>
   140003cbd:	44 8b 94 24 b0 00 00 	mov    r10d,DWORD PTR [rsp+0xb0]
   140003cc4:	00 
   140003cc5:	f2 0f 10 9c 24 98 00 	movsd  xmm3,QWORD PTR [rsp+0x98]
   140003ccc:	00 00 
   140003cce:	e9 dd fb ff ff       	jmp    1400038b0 <dstedc_+0x6d0>
   140003cd3:	0f af c9             	imul   ecx,ecx
   140003cd6:	4c 8d 04 c5 f8 ff ff 	lea    r8,[rax*8-0x8]
   140003cdd:	ff 
   140003cde:	48 89 84 24 98 00 00 	mov    QWORD PTR [rsp+0x98],rax
   140003ce5:	00 
   140003ce6:	48 8b 84 24 80 01 00 	mov    rax,QWORD PTR [rsp+0x180]
   140003ced:	00 
   140003cee:	4c 8d a4 24 dc 00 00 	lea    r12,[rsp+0xdc]
   140003cf5:	00 
   140003cf6:	48 89 6c 24 38       	mov    QWORD PTR [rsp+0x38],rbp
   140003cfb:	4e 8d 0c 06          	lea    r9,[rsi+r8*1]
   140003cff:	49 01 d8             	add    r8,rbx
   140003d02:	48 89 44 24 20       	mov    QWORD PTR [rsp+0x20],rax
   140003d07:	48 63 d1             	movsxd rdx,ecx
   140003d0a:	4c 89 64 24 28       	mov    QWORD PTR [rsp+0x28],r12
   140003d0f:	48 8d 0d 3c 05 22 01 	lea    rcx,[rip+0x122053c]        # 141224252 <.rdata+0x2>
   140003d16:	48 8d 14 d0          	lea    rdx,[rax+rdx*8]
   140003d1a:	48 c7 44 24 40 01 00 	mov    QWORD PTR [rsp+0x40],0x1
   140003d21:	00 00 
   140003d23:	48 89 54 24 30       	mov    QWORD PTR [rsp+0x30],rdx
   140003d28:	4c 89 e2             	mov    rdx,r12
   140003d2b:	44 89 94 24 b8 00 00 	mov    DWORD PTR [rsp+0xb8],r10d
   140003d32:	00 
   140003d33:	f2 0f 11 9c 24 b0 00 	movsd  QWORD PTR [rsp+0xb0],xmm3
   140003d3a:	00 00 
   140003d3c:	e8 ff 01 00 00       	call   140003f40 <dsteqr_>
   140003d41:	48 89 7c 24 30       	mov    QWORD PTR [rsp+0x30],rdi
   140003d46:	4d 89 e0             	mov    r8,r12
   140003d49:	48 89 fa             	mov    rdx,rdi
   140003d4c:	48 8b 84 24 98 00 00 	mov    rax,QWORD PTR [rsp+0x98]
   140003d53:	00 
   140003d54:	48 0f af 84 24 a8 00 	imul   rax,QWORD PTR [rsp+0xa8]
   140003d5b:	00 00 
   140003d5d:	48 c7 44 24 38 01 00 	mov    QWORD PTR [rsp+0x38],0x1
   140003d64:	00 00 
   140003d66:	48 8b 8c 24 a0 00 00 	mov    rcx,QWORD PTR [rsp+0xa0]
   140003d6d:	00 
   140003d6e:	4c 8b bc 24 c0 00 00 	mov    r15,QWORD PTR [rsp+0xc0]
   140003d75:	00 
   140003d76:	48 8d 44 01 01       	lea    rax,[rcx+rax*1+0x1]
   140003d7b:	48 8b 8c 24 70 01 00 	mov    rcx,QWORD PTR [rsp+0x170]
   140003d82:	00 
   140003d83:	4c 89 7c 24 28       	mov    QWORD PTR [rsp+0x28],r15
   140003d88:	4c 8d 2c c1          	lea    r13,[rcx+rax*8]
   140003d8c:	48 8b 84 24 78 01 00 	mov    rax,QWORD PTR [rsp+0x178]
   140003d93:	00 
   140003d94:	48 8d 0d f5 04 22 01 	lea    rcx,[rip+0x12204f5]        # 141224290 <.rdata+0x40>
   140003d9b:	4d 89 e9             	mov    r9,r13
   140003d9e:	48 89 44 24 20       	mov    QWORD PTR [rsp+0x20],rax
   140003da3:	e8 18 e9 ff ff       	call   1400026c0 <dlacpy_>
   140003da8:	4c 89 6c 24 58       	mov    QWORD PTR [rsp+0x58],r13
   140003dad:	4d 89 e1             	mov    r9,r12
   140003db0:	49 89 f8             	mov    r8,rdi
   140003db3:	48 8b 84 24 78 01 00 	mov    rax,QWORD PTR [rsp+0x178]
   140003dba:	00 
   140003dbb:	4c 89 64 24 48       	mov    QWORD PTR [rsp+0x48],r12
   140003dc0:	48 8d 15 89 04 22 01 	lea    rdx,[rip+0x1220489]        # 141224250 <.rdata>
   140003dc7:	48 c7 44 24 70 01 00 	mov    QWORD PTR [rsp+0x70],0x1
   140003dce:	00 00 
   140003dd0:	48 89 d1             	mov    rcx,rdx
   140003dd3:	48 89 44 24 60       	mov    QWORD PTR [rsp+0x60],rax
   140003dd8:	48 8d 05 89 04 22 01 	lea    rax,[rip+0x1220489]        # 141224268 <.rdata+0x18>
   140003ddf:	48 89 44 24 50       	mov    QWORD PTR [rsp+0x50],rax
   140003de4:	48 8b 84 24 80 01 00 	mov    rax,QWORD PTR [rsp+0x180]
   140003deb:	00 
   140003dec:	48 c7 44 24 68 01 00 	mov    QWORD PTR [rsp+0x68],0x1
   140003df3:	00 00 
   140003df5:	48 89 44 24 40       	mov    QWORD PTR [rsp+0x40],rax
   140003dfa:	48 8d 05 77 04 22 01 	lea    rax,[rip+0x1220477]        # 141224278 <.rdata+0x28>
   140003e01:	48 89 7c 24 38       	mov    QWORD PTR [rsp+0x38],rdi
   140003e06:	4c 89 7c 24 30       	mov    QWORD PTR [rsp+0x30],r15
   140003e0b:	48 89 44 24 28       	mov    QWORD PTR [rsp+0x28],rax
   140003e10:	4c 89 64 24 20       	mov    QWORD PTR [rsp+0x20],r12
   140003e15:	e8 76 3a 00 00       	call   140007890 <dgemm_>
   140003e1a:	44 8b 94 24 b8 00 00 	mov    r10d,DWORD PTR [rsp+0xb8]
   140003e21:	00 
   140003e22:	f2 0f 10 9c 24 b0 00 	movsd  xmm3,QWORD PTR [rsp+0xb0]
   140003e29:	00 00 
   140003e2b:	e9 80 fa ff ff       	jmp    1400038b0 <dstedc_+0x6d0>
   140003e30:	8d 48 01             	lea    ecx,[rax+0x1]
   140003e33:	83 f8 1f             	cmp    eax,0x1f
   140003e36:	74 0e                	je     140003e46 <dstedc_+0xc66>
   140003e38:	41 d3 e0             	shl    r8d,cl
   140003e3b:	89 c8                	mov    eax,ecx
   140003e3d:	44 39 c2             	cmp    edx,r8d
   140003e40:	0f 8e 7c f6 ff ff    	jle    1400034c2 <dstedc_+0x2e2>
   140003e46:	8d 41 01             	lea    eax,[rcx+0x1]
   140003e49:	e9 74 f6 ff ff       	jmp    1400034c2 <dstedc_+0x2e2>
   140003e4e:	0f af c2             	imul   eax,edx
   140003e51:	41 89 d0             	mov    r8d,edx
   140003e54:	66 0f ef c9          	pxor   xmm1,xmm1
   140003e58:	44 0f af c2          	imul   r8d,edx
   140003e5c:	89 c1                	mov    ecx,eax
   140003e5e:	8d 44 52 01          	lea    eax,[rdx+rdx*2+0x1]
   140003e62:	8d 04 48             	lea    eax,[rax+rcx*2]
   140003e65:	8d 0c 89             	lea    ecx,[rcx+rcx*4]
   140003e68:	42 8d 04 80          	lea    eax,[rax+r8*4]
   140003e6c:	44 8d 44 52 03       	lea    r8d,[rdx+rdx*2+0x3]
   140003e71:	46 8d 1c 41          	lea    r11d,[rcx+r8*2]
   140003e75:	f2 0f 2a c8          	cvtsi2sd xmm1,eax
   140003e79:	e9 0f f5 ff ff       	jmp    14000338d <dstedc_+0x1ad>
   140003e7e:	45 89 fb             	mov    r11d,r15d
   140003e81:	66 0f 28 ce          	movapd xmm1,xmm6
   140003e85:	e9 73 f7 ff ff       	jmp    1400035fd <dstedc_+0x41d>
   140003e8a:	8b 07                	mov    eax,DWORD PTR [rdi]
   140003e8c:	44 8b 9c 24 cc 00 00 	mov    r11d,DWORD PTR [rsp+0xcc]
   140003e93:	00 
   140003e94:	66 0f 28 ce          	movapd xmm1,xmm6
   140003e98:	83 c0 01             	add    eax,0x1
   140003e9b:	41 0f af c2          	imul   eax,r10d
   140003e9f:	44 01 f0             	add    eax,r14d
   140003ea2:	89 45 00             	mov    DWORD PTR [rbp+0x0],eax
   140003ea5:	e9 53 f7 ff ff       	jmp    1400035fd <dstedc_+0x41d>
   140003eaa:	49 89 e9             	mov    r9,rbp
   140003ead:	49 89 d8             	mov    r8,rbx
   140003eb0:	48 8d 0d 9b 03 22 01 	lea    rcx,[rip+0x122039b]        # 141224252 <.rdata+0x2>
   140003eb7:	48 89 fa             	mov    rdx,rdi
   140003eba:	48 c7 44 24 20 01 00 	mov    QWORD PTR [rsp+0x20],0x1
   140003ec1:	00 00 
   140003ec3:	44 89 9c 24 8c 00 00 	mov    DWORD PTR [rsp+0x8c],r11d
   140003eca:	00 
   140003ecb:	f2 0f 11 b4 24 90 00 	movsd  QWORD PTR [rsp+0x90],xmm6
   140003ed2:	00 00 
   140003ed4:	e8 a7 30 d9 00       	call   140d96f80 <dlasrt_>
   140003ed9:	44 8b 9c 24 8c 00 00 	mov    r11d,DWORD PTR [rsp+0x8c]
   140003ee0:	00 
   140003ee1:	f2 0f 10 8c 24 90 00 	movsd  xmm1,QWORD PTR [rsp+0x90]
   140003ee8:	00 00 
   140003eea:	e9 0e f7 ff ff       	jmp    1400035fd <dstedc_+0x41d>
   140003eef:	8b b4 24 dc 00 00 00 	mov    esi,DWORD PTR [rsp+0xdc]
   140003ef6:	99                   	cdq
   140003ef7:	44 8b 9c 24 cc 00 00 	mov    r11d,DWORD PTR [rsp+0xcc]
   140003efe:	00 
   140003eff:	66 0f 28 ce          	movapd xmm1,xmm6
   140003f03:	8d 4e 01             	lea    ecx,[rsi+0x1]
   140003f06:	f7 f9                	idiv   ecx
   140003f08:	8b 0f                	mov    ecx,DWORD PTR [rdi]
   140003f0a:	83 c1 01             	add    ecx,0x1
   140003f0d:	41 8d 44 02 ff       	lea    eax,[r10+rax*1-0x1]
   140003f12:	0f af c1             	imul   eax,ecx
   140003f15:	01 d0                	add    eax,edx
   140003f17:	41 8d 44 02 ff       	lea    eax,[r10+rax*1-0x1]
   140003f1c:	89 45 00             	mov    DWORD PTR [rbp+0x0],eax
   140003f1f:	e9 d9 f6 ff ff       	jmp    1400035fd <dstedc_+0x41d>
   140003f24:	f7 d8                	neg    eax
   140003f26:	4c 8d 15 2c 03 22 01 	lea    r10,[rip+0x122032c]        # 141224259 <.rdata+0x9>
   140003f2d:	e9 92 f3 ff ff       	jmp    1400032c4 <dstedc_+0xe4>
   140003f32:	90                   	nop
   140003f33:	90                   	nop
   140003f34:	90                   	nop
   140003f35:	90                   	nop
   140003f36:	90                   	nop
   140003f37:	90                   	nop
   140003f38:	90                   	nop
   140003f39:	90                   	nop
   140003f3a:	90                   	nop
   140003f3b:	90                   	nop
   140003f3c:	90                   	nop
   140003f3d:	90                   	nop
   140003f3e:	90                   	nop
   140003f3f:	90                   	nop
