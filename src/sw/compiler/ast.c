#include "ast.h"
#include <stdio.h>
#include <string.h>

//creates a new expression node
AstNodePtr new_ExprNode(ExpKind kind, char *reference, int referenceLength){
	AstNodePtr node = NULL;
	int i;
	node = (AstNodePtr)malloc(sizeof(AstNode));
	if(node!=NULL){
		node->eKind = kind;
		node->reference = reference;
		node->referenceLength = referenceLength;
		node->child = NULL;
		node->brother = NULL;
		node->absAddress = 0;
		node->jump = 0;
	}else{
		printf("Error during creation of a new node!\n");
	}
	return node;
}

void delete_ExprNode(AstNodePtr node){
		node->reference = NULL;
		node->child = NULL;
		node->brother = NULL;
		free(node);
}

void printAST(AstNodePtr root, int nspace){
	int i, len;
	if(root==NULL)
		return;
	printf("%*s", nspace,"");
	printf("%d ", root->absAddress);
	printf(" %d ", root->jump);
	printOp(root->eKind);
	if(root->reference != NULL){
		len = root->referenceLength;
		for(i = 0; i < len; i++){
			if(!isprint(*(root->reference + i))){
				if(*(root->reference + i) == '\n')
					printf("\\n");
				else
					if(*(root->reference + i) == '\t')
						printf("\\t");
					else
						if(*(root->reference + i) == '\r')
							printf("\\r");
						else
							if(*(root->reference + i) == '\v')
								printf("\\v");
							else
								if(*(root->reference + i) == '\f')
									printf("\\f");
								else
									printf(" ");
			}
			else{
				printf("%c", *(root->reference + i));
			}
		}
	}
	printf("\n");
	printAST(root->child, nspace + 1);
	printAST(root->brother, nspace);
}

int fixAST(OptStruct *opt, AstNodePtr root, int instrCount, int negate, int callOpCounter, ExpKind parentEkind){
	//not is supported only inside [] so it possible negate only RANGEs or ORs
	char *ref, *tmpRef;
	int length, diff;
	int i, negateTmp;
	int actualAdress;
	int callOpCounterTmp;
	ExpKind rootEkind;
	AstNodePtr tmp, actual, brother, child;
	

	if(root==NULL)
		return instrCount;
	if(root->eKind != NOT_EXP && root->eKind != LAZY_EXP){
		root->absAddress = ++instrCount;
		negateTmp = 0;
	}
	else{
		negateTmp = 1;
		root->absAddress = instrCount + 1;
	}
	//overbrakets
	if(root->eKind == CMPLX_EXP){
		if(root->brother == NULL){
			root->eKind = root->child->eKind;
			root->brother = root->child->brother;
			root->reference = root->child->reference;
			root->referenceLength = root->child->referenceLength;
			tmp = root->child;
			root->child = root->child->child;
			delete_ExprNode(tmp);
			tmp = NULL;
		}
		else
			root->eKind = OPCP_EXP;
	}
	if(root->eKind == OPCP_EXP && root->child->eKind == CMPLX_EXP){
		tmp = root->child;
		root->child = root->child->child;
		delete_ExprNode(tmp);
		tmp = NULL;
	}

	if(root->eKind == OR_EXP && root->child != NULL){
		if(negate == 0){
			root->eKind = OPCPOR_EXP;
			 actual = root->child;
			brother = root->brother;
			while(actual != NULL){
				if(actual->eKind != OPCP_EXP){
					tmp = new_ExprNode(actual->eKind, actual->reference, actual->referenceLength);
					tmp->child = actual->child;
					actual->reference = NULL;
					actual->child = tmp;
					actual->eKind = OPCP_EXP;
				}
				if(actual->brother != NULL)
					actual->eKind = OPCPOR_EXP;
				actual = actual->brother;
			}
			root->brother = root->child->brother;
			root->reference = root->child->reference;
			tmp = root->child;
			root->child = root->child->child;
			delete_ExprNode(tmp);
			tmp = NULL;
		}
		else{
			//TO-DO: a special control operato must be implement to support this operator
			actual = root->child;
			while(actual != NULL){
				tmp = actual->child;
				actual->eKind = tmp->eKind;
				actual->reference = tmp->reference;
				actual->referenceLength = tmp->referenceLength;
				delete_ExprNode(tmp);
			    actual->child = NULL;
			    tmp = actual;
				actual = actual->brother;
			}
			root->eKind = root->child->eKind;
			root->reference = root->child->reference;
			root->referenceLength = root->child->referenceLength;
			tmp->brother = root->brother;
			root->brother = root->child->brother;
			delete_ExprNode(root->child);
			root->child = NULL;
		}
	} 


	if(isCallOp(root->eKind)){
	   callOpCounterTmp = (root->brother == NULL) ? callOpCounter + 1 : 1;
		if(root->eKind == OPCPSTAR_EXP){
			root->reference = strdup("0,inf");
			root->referenceLength = strlen(root->reference);
			root->eKind = QUANTIFIER_EXP;
  	   }else
  	   	if(root->eKind == OPCPLUS_EXP){
				root->reference = strdup("1,inf");
				root->referenceLength = strlen(root->reference);
				root->eKind = QUANTIFIER_EXP;
			}
	}
	else
		callOpCounterTmp = 0;

	actualAdress = fixAST(opt, root->child, instrCount, (negate | negateTmp), callOpCounterTmp, root->eKind);
	brother = root->brother;
	if(((length = root->referenceLength) > opt->clusterWidth)){
		if(root->eKind == AND_EXP){
			actual = root;
			i = opt->clusterWidth;
			ref = root->reference;
			if(tmpRef = (char *)malloc(sizeof(char)*(opt->clusterWidth))){
				memcpy(tmpRef, ref, opt->clusterWidth);
				actual->absAddress = actualAdress++;
				actual->reference = tmpRef;
				actual->referenceLength = opt->clusterWidth;
			}
	     	else
	     		printf("fatal error");
			while(i < length){
			      diff = ((length - i) > opt->clusterWidth) ? opt->clusterWidth : length - i;
				  if(tmpRef = (char *)malloc(sizeof(char)*(diff))){
				  	memcpy(tmpRef, ref + i, diff);
				  	tmp = new_ExprNode(AND_EXP, tmpRef, diff);
					actual->brother = tmp;
					tmp->absAddress = actualAdress++;
					actual = tmp;
				}
	     		else
	     			printf("fatal error");
	     	i+=opt->clusterWidth;
	       }
	       actualAdress--;
	       actual->brother = brother;
	       free(ref);
	       ref = NULL;
	   }else
			if(root->eKind == OR_EXP || root->eKind == RANGE_EXP){
   				if(negate == 0){
	   				rootEkind = root->eKind;
	   				root->eKind = OPCPOR_EXP;
	   				ref = root->reference;
	   				root->reference = NULL;
	   				i = 0;
	   				actual = root;
	   				actual->absAddress = actualAdress++;
	   				do{
	   				   if(tmpRef = (char *)malloc(sizeof(char)*(opt->clusterWidth))){
				    	  memcpy(tmpRef, ref + i, opt->clusterWidth);
				     	  tmp = new_ExprNode(rootEkind, tmpRef, opt->clusterWidth);
				     	  tmp->absAddress = actualAdress++;
				     	  actual->child = tmp;
				     	  tmp = new_ExprNode(OPCPOR_EXP, NULL, 0);
				     	  tmp->absAddress = actualAdress++;
				    	  actual->brother = tmp;
				     	  actual = tmp;
				       }
				       else
				     	 printf("fatal error");
				       i+=opt->clusterWidth;
					}while(length > i + opt->clusterWidth);
					diff = length - i; 
					if(tmpRef = (char *)malloc(sizeof(char)*(diff))){
						tmp->eKind = OPCP_EXP;
						memcpy(tmpRef, ref + i, diff);
						tmp = new_ExprNode(rootEkind, tmpRef, diff);
						actual->child = tmp;
						tmp->absAddress = actualAdress;
						actual->brother = brother;
					}
					else
						 printf("fatal error");
					free(ref);	
					ref = NULL;
				}
				else{
					rootEkind = root->eKind;
					ref = root->reference;
	   				i = 0;
	   				actual = root;
	   				actual->referenceLength = opt->clusterWidth;
	   				do{
	   				   if(tmpRef = (char *)malloc(sizeof(char)*(opt->clusterWidth))){
				    	  memcpy(tmpRef, ref + i, opt->clusterWidth);
				    	  actual->reference = tmpRef;
				     	  tmp = new_ExprNode(rootEkind, NULL, opt->clusterWidth);
				     	  tmp->absAddress = actualAdress++;
				     	  actual->brother = tmp;
				     	  actual = tmp;
				       }
				       else
				     	 printf("fatal error");
				       i+=opt->clusterWidth;
					}while(length > i + opt->clusterWidth);
					diff = length - i; 
					if(tmpRef = (char *)malloc(sizeof(char)*(diff))){
						memcpy(tmpRef, ref + i, diff);
						actual->reference = tmpRef;
						actual->brother = brother;
					}
					else
						 printf("fatal error");
				}
				free(ref);	
				ref = NULL; 
			}
   	}

		if(root->brother != NULL)
			actualAdress = fixAST(opt, brother, actualAdress, negate, callOpCounter, parentEkind);
		else
			if(isCallOp(root->eKind) && isCallOp(parentEkind)){
				actualAdress++;
			}
   	    
   	return actualAdress;
}	

void translateAST(OptStruct *opt, AstNodePtr root){
	int numInstr;
	if(root==NULL)
		return;
	numInstr = fixAST(opt, root, -1, 0, 0, NOOP_EXP) + 1;
	jumpCalculator(root, numInstr, NOOP_EXP);
	printf("\nFixed AST: \n");
	printAST(root, 0);
	printf("Number of instructions %d\n", numInstr);
	numInstr = middleend(root, -1, NOOP_EXP, 0, NOOP_EXP) + 1;
	jumpCalculator(root, numInstr, NOOP_EXP);
	printf("\nOptimized AST: \n");
	printAST(root, 0);
	printf("Number of instructions %d\n", numInstr);
	backend(opt, root, NOOP_EXP, 0);
	if(opt->nopFill)
		nopFill(opt, numInstr);
}

void jumpCalculator(AstNodePtr root, int jumpAddress, ExpKind parentEkind){
	int callOpCounterTmp;
	int jumpAddressTmp;
	AstNodePtr brother;
	if(root == NULL)
		return;
	if(isCallOp(root->eKind)){
		brother = root->brother;	
		if(root->eKind == OPCPOR_EXP){
			while(brother->eKind != OPCP_EXP){
				brother = brother->brother;
			}
			brother = brother->brother;
		}
		if(brother == NULL){ 
			jumpAddressTmp = (!isCallOp(parentEkind)) ? jumpAddress : jumpAddress -1;
		}else
			jumpAddressTmp = brother->absAddress;
		
		if(root->eKind != OPCP_EXP){
			if(brother != NULL)
				root->jump = brother->absAddress - root->absAddress;
			else	
				root->jump = jumpAddressTmp - root->absAddress;
		}
	}
	else
		jumpAddressTmp = jumpAddress;
	jumpCalculator(root->child, jumpAddressTmp, root->eKind);
	jumpCalculator(root->brother, jumpAddress, parentEkind);
}

void nopFill(OptStruct *opt, int numInstr){
	int n = opt->numInstr - numInstr;
	int i;
	int referenceWidth = opt->lineWidth;
	char *reference;
    if(!(reference = (char *)malloc(sizeof(char)*referenceWidth)))
    	return;
	for(i = 0; i < referenceWidth; i++)
		*(reference + i) = '0';
	for(i = 0; i < n; i++){
		fprintf(opt->fileOutPtr, "%.*s\n", referenceWidth, reference);
		fprintf(opt->fileOutPtr, "%.*s\n", referenceWidth, reference);
	}
	free(reference);
}

int middleend(AstNodePtr root, int instrCount, ExpKind brotherEkind, int callOpCounter, ExpKind parentEkind){
	int actualAdress;
	int callOpCounterTmp;
	AstNodePtr brother, nextBrother, child;
	const char s[2] = ",";
	char *content, *refTmp;

	if(root == NULL)
		return instrCount;
	if(root->eKind != NOT_EXP && root->eKind != LAZY_EXP)
	  	  root->absAddress = ++instrCount;
	else{
		root->absAddress = instrCount + 1;
	}

	if(root->eKind == OPCP_EXP){
		do{
			if(brotherEkind != OPCPOR_EXP){
				brother = root->brother;
				nextBrother = root->brother = root->child->brother;
				root->eKind = root->child->eKind;
				root->reference = root->child->reference;
				root->referenceLength = root->child->referenceLength;
				child = root->child;
				root->child = root->child->child;
				if(nextBrother != NULL){
					while(nextBrother->brother != NULL)
						nextBrother = nextBrother->brother;
					nextBrother->brother = brother;
				}
				else
					root->brother = brother;
				delete_ExprNode(child);
				child = NULL;
			}
		}while(root->eKind == OPCP_EXP && brotherEkind != OPCPOR_EXP);
		if(root->eKind == NOT_EXP || root->eKind == LAZY_EXP)
	  	  root->absAddress = --instrCount;
	}

	if(root->eKind == OPCPOR_EXP){
		if(root->child->eKind == OPCPOR_EXP){
			brother = root->child->brother;
			while(brother->eKind != OPCP_EXP)
				brother = brother->brother;
			if(brother->brother == NULL){
				brother->brother = root->brother;
				brother->eKind = OPCPOR_EXP;
				root->brother = root->child->brother;
				child = root->child;
				root->child = root->child->child;
				delete_ExprNode(child);
				child = NULL;
			}
		}
	}
	else{
		if(root->eKind == LAZY_EXP && root->child->brother == NULL && root->child->eKind == QUANTIFIER_EXP){
			child = root->child;
			if(!(refTmp = (char *)malloc(sizeof(char)*child->referenceLength)))
				return -1;
			memcpy(refTmp, child->reference, child->referenceLength);
			content = strtok(refTmp, s);
			content = strtok(NULL, s);
			root->child = root->child->child;
			root->reference = child->reference;
			root->referenceLength = child->referenceLength;
			delete_ExprNode(child);
			child = NULL;
			root->absAddress = ++instrCount;
			if(content != NULL){
				root->eKind = QUANTIFIER_LAZY_EXP;
			} 
			else{
				root->eKind = QUANTIFIER_EXP;
			}
			free(refTmp);
			refTmp = NULL;
		}
	}
	if(isCallOp(root->eKind))
	     callOpCounterTmp = (root->brother == NULL) ? callOpCounter + 1 : 1;
	else
		callOpCounterTmp = 0;

	actualAdress = middleend(root->child, instrCount, NOOP_EXP, callOpCounterTmp, root->eKind);

	if(root->brother != NULL)
		actualAdress = middleend(root->brother, actualAdress, root->eKind, callOpCounter, parentEkind);
	else
		if(isCallOp(root->eKind) && isCallOp(parentEkind)){
			actualAdress++;
		}
	return actualAdress;
}

void backend(OptStruct *opt, AstNodePtr root, ExpKind parentEkind, int negate){
	int referenceWidth = opt->lineWidth;
	char *reference, *partialReference;
	char *op1;
	char *op2;
	const char s[2] = ",";
	char *min, *max;
	int max_value;

   if(!(reference = (char *)malloc(sizeof(char)*referenceWidth)) ||
       !(op1 = (char *)malloc(sizeof(char)*referenceWidth)) ||
       !(op2 = (char *)malloc(sizeof(char)*referenceWidth)))
    	return;
	int i;
	for(i = 0; i < referenceWidth; i++){
		*(reference + i) = '0';
		*(op1 + i) = '0';
		*(op2 + i) = '0';
	}

	if(root==NULL)
		return;
	callOptoStr(opt, op1, root->eKind);
	if(root->eKind == QUANTIFIER_EXP || root->eKind == QUANTIFIER_LAZY_EXP){
		partialReference = reference + (referenceWidth - 4*QUANTIZER_STACKCOUNTING_BITWIDTH);
		min = strtok(root->reference, s);
		max = strtok(NULL, s);
		max = (max != NULL) ? max : min;
		max_value = atoi(max);
		max_value = (max_value == 0 && max != NULL && strcmp(max, "0") != 0) ? COUNTER_INFINITE : max_value;
		integerToAscii(atoi(min), partialReference, QUANTIZER_STACKCOUNTING_BITWIDTH);
		partialReference += QUANTIZER_STACKCOUNTING_BITWIDTH;
		integerToAscii(max_value, partialReference, QUANTIZER_STACKCOUNTING_BITWIDTH);
		partialReference += QUANTIZER_STACKCOUNTING_BITWIDTH;
		if(root->eKind == QUANTIFIER_LAZY_EXP){
			integerToAscii(root->jump, partialReference, QUANTIZER_STACKCOUNTING_BITWIDTH);
			partialReference += QUANTIZER_STACKCOUNTING_BITWIDTH;
			integerToAscii(0, partialReference, QUANTIZER_STACKCOUNTING_BITWIDTH);
		}
		else{
			integerToAscii(0, partialReference, QUANTIZER_STACKCOUNTING_BITWIDTH);
			partialReference += QUANTIZER_STACKCOUNTING_BITWIDTH;
			integerToAscii(root->jump, partialReference, QUANTIZER_STACKCOUNTING_BITWIDTH);
		}
		*(reference + 0) = '1';
		*(reference + 1) = '1';
		*(reference + 2) = '1';
		*(reference + 3) = '1';
		if(root->eKind == QUANTIFIER_LAZY_EXP)
			*(reference + 4) = '1';
		free(root->reference);
		root->reference = NULL;
	}
	else 
		if(root->reference != NULL){
   			stringToReference(opt, root->reference, root->referenceLength, reference);
			integerToAscii((1<<opt->clusterWidth) - (1<<(opt->clusterWidth - root->referenceLength)),
			 op1 + (referenceWidth - OPCODE_LEN - opt->clusterWidth), opt->clusterWidth);	
		}
   	else
			if(root->eKind == OPCPOR_EXP){
				partialReference = reference + (referenceWidth - 2*QUANTIZER_STACKCOUNTING_BITWIDTH);
				integerToAscii(root->brother->absAddress - root->absAddress, partialReference, QUANTIZER_STACKCOUNTING_BITWIDTH);
				partialReference += QUANTIZER_STACKCOUNTING_BITWIDTH;
				integerToAscii(root->jump, partialReference, QUANTIZER_STACKCOUNTING_BITWIDTH);
				*(reference + 2) = '1';
				*(reference + 3) = '1';
		}
	if(!isCallOp(root->eKind)){
		intOptoStr(opt, op1, root->eKind, negate);
		if(root->brother == NULL)
		  if(isCallOp(parentEkind))
		  	extOptoStr(opt, op1, parentEkind);
	}
	if(root->eKind == NOT_EXP){
		if(root->child != NULL && root->child->reference != NULL && *(root->child->reference) == '\n'){
			free(root->child->reference);
			if(root->child->reference = (char *)malloc(sizeof(char)*(opt->clusterWidth))){
				int r;
				for(r = 0; r < (opt->clusterWidth); r++)
					*(root->child->reference + r) = '\n';
				root->child->referenceLength = opt->clusterWidth;
			}else
			 printf("fatal error");
		}
		backend(opt, root->child, parentEkind, 1);
	}else
		if(root->eKind == LAZY_EXP){
			backend(opt, root->child, root->eKind, 0);
		}
		else{
			fprintf(opt->fileOutPtr, "%.*s\n", referenceWidth, reference);
			fprintf(opt->fileOutPtr, "%.*s\n", referenceWidth, op1);
			backend(opt, root->child, root->eKind, negate);
		}
	backend(opt, root->brother, parentEkind, negate);
	if(isCallOp(root->eKind) && root->brother == NULL 
		&& isCallOp(parentEkind)){
		fprintf(opt->fileOutPtr, "%.*s\n", referenceWidth, op2);
		extOptoStr(opt, op2, parentEkind);
		fprintf(opt->fileOutPtr, "%.*s\n", referenceWidth, op2);
	}
	free(reference);
	free(op1);
	free(op2);
}

void integerToAscii(int character, char ascii[], int size){
	int i = 0;
	for(i = 0; i < size; i++){
		ascii[i] = (character & (1 << (size - i -1))) ? '1' : '0';
	}

}

void stringToReference(OptStruct *opt, char referenceStr[], int referenceLength, char reference[]){
	int length = referenceLength;
	int i, jump;
	if(opt->clusterWidth > length)
		jump = 0;	
	else
		jump = opt->lineWidth - opt->wordWidth*length; 
	for(i = 0; i < length; i++)
		integerToAscii(referenceStr[i], &(reference[i*(opt->wordWidth)+jump]), opt->wordWidth);
}

void intOptoStr(OptStruct *opt, char v[], ExpKind ekind, int negate){
	switch(ekind){
		case OR_EXP:
			strncpy(&(v[opt->lineWidth-6]), "001", 3);
			break;
		case AND_EXP:
			strncpy(&(v[opt->lineWidth-6]), "010", 3);
			break;
		case RANGE_EXP:
			strncpy(&(v[opt->lineWidth-6]), "011", 3);
			break;
		}
	if(negate == 1)
		v[opt->lineWidth-6] = '1';
}

void extOptoStr(OptStruct *opt, char v[], ExpKind ekind){
	switch(ekind){
		case OPCP_EXP:
			strncpy(&(v[opt->lineWidth-3]), "100", 3);
			break;
		case QUANTIFIER_EXP:
		case OPCPSTAR_EXP:
		case OPCPLUS_EXP:
			strncpy(&(v[opt->lineWidth-3]), "010", 3);
			break;
		case QUANTIFIER_LAZY_EXP:
			strncpy(&(v[opt->lineWidth-3]), "001", 3);
			break;
		case OPCPOR_EXP:
			strncpy(&(v[opt->lineWidth-3]), "011", 3);
			break;
		}
}

void callOptoStr(OptStruct *opt, char v[], ExpKind ekind){
	switch(ekind){
		case OPCPLUS_EXP:	
		case OPCP_EXP:
		case OPCPSTAR_EXP:
		case OPCPOR_EXP:
		case QUANTIFIER_EXP:
		case QUANTIFIER_LAZY_EXP:
			strncpy(&(v[opt->lineWidth-7]), "1", 1);
		}
}

int isCallOp(ExpKind kind){
	int response = 0;
	switch(kind){
		case OPCP_EXP:
		case OPCPSTAR_EXP:
		case OPCPLUS_EXP:
		case OPCPOR_EXP:
		case QUANTIFIER_EXP:
		case QUANTIFIER_LAZY_EXP:
			response = 1;
		}
	return response;
}

void OptStructInit(OptStruct *opt){
	opt->outputFile = OUTPUTFILE;
	opt->inputFile = INPUTFILE;
	opt->wordWidth = WORDWIDTH;
	opt->lineWidth = LINEWIDTH;
	opt->clusterWidth = CLUSTERWIDTH;
	opt->nopFill = NOPFILL;
	opt->fileInPtr = stdin;
	opt->fileOutPtr = stdout;
	opt->numInstr = (1 << MEMWIDTH);
}

int isInternalOp(ExpKind kind){
	int response = 0;
	switch(kind){
		case OR_EXP:
		case AND_EXP:
		case RANGE_EXP:
			response = 1;
		}
	return response;
}

void printOp(ExpKind kind){
	switch(kind){
	    case OR_EXP:
			printf("OR: ");
			break;
		case AND_EXP:
			printf("AND: ");
			break;
		case RANGE_EXP:
			printf("RANGE: ");
			break;
		case NOT_EXP:
			printf("NOT: ");
			break;
		case OPCP_EXP:
			printf("OPCP");
			break;
		case OPCPSTAR_EXP:
			printf("OPCPSTAR");
			break;
		case OPCPLUS_EXP:
			printf("OPCPLUS");
			break;
		case OPCPOR_EXP:
			printf("OPCPOR");
			break;
		case CMPLX_EXP:
			printf("CMPLX");
			break;
		case QUANTIFIER_EXP:
			printf("QUANTIFIER: ");
			break;
		case QUANTIFIER_LAZY_EXP:
			printf("QUANTIFIER_LAZY_EXP: ");
			break;
		case LAZY_EXP:
			printf("LAZY");
			break;
		}
}
