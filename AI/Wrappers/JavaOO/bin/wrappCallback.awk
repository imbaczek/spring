#!/bin/awk
#
# This awk script creates Java classes in OO style to wrapp the C style
# JNI based AI Callback wrapper.
# In other words, the output of this file wrapps:
# com/springrts/ai/AICallback.java
# which wrapps:
# rts/ExternalAI/Interface/SSkirmishAICallback.h
# and
# rts/ExternalAI/Interface/AISCommands.h
#
# This script uses functions from the following files:
# * common.awk
# * commonDoc.awk
# * commonOOCallback.awk
# Variables that can be set on the command-line (with -v):
# * GENERATED_SOURCE_DIR           : the generated sources root dir
# * JAVA_GENERATED_SOURCE_DIR      : the generated java sources root dir
# * INTERFACE_SOURCE_DIR           : the Java AI Interfaces static source files root dir
# * INTERFACE_GENERATED_SOURCE_DIR : the Java AI Interfaces generated source files root dir
#
# usage:
# 	awk -f thisScript.awk -f common.awk -f commonDoc.awk -f commonOOCallback.awk
# 	awk -f thisScript.awk -f common.awk -f commonDoc.awk -f commonOOCallback.awk \
#       -v 'GENERATED_SOURCE_DIR=/tmp/build/AI/Interfaces/Java/src-generated'
#

BEGIN {
	# initialize things

	# define the field splitter(-regex)
	FS = "(\\()|(\\)\\;)";
	IGNORECASE = 0;

	# Used by other scripts
	JAVA_MODE = 1;

	# These vars can be assigned externally, see file header.
	# Set the default values if they were not supplied on the command line.
	if (!GENERATED_SOURCE_DIR) {
		GENERATED_SOURCE_DIR = "../src-generated/main";
	}
	if (!JAVA_GENERATED_SOURCE_DIR) {
		JAVA_GENERATED_SOURCE_DIR = GENERATED_SOURCE_DIR "/java";
	}
	if (!INTERFACE_SOURCE_DIR) {
		INTERFACE_SOURCE_DIR = "../../../Interfaces/Java/src/main/java";
	}
	if (!INTERFACE_GENERATED_SOURCE_DIR) {
		INTERFACE_GENERATED_SOURCE_DIR = "../../../Interfaces/Java/src-generated/main/java";
	}

	myMainPkgA     = "com.springrts.ai";
	myParentPkgA   = myMainPkgA ".oo";
	myPkgA         = myParentPkgA ".clb";
	myPkgD         = convertJavaNameFormAToD(myPkgA);
	myClass        = "OOAICallback";
	myClassVar     = "ooClb";
	myWrapClass    = "AICallback";
	myWrapVar      = "innerCallback";
	defMapJavaImpl = "HashMap";

	myBufferedClasses["_UnitDef"]    = 1;
	myBufferedClasses["_WeaponDef"]  = 1;
	myBufferedClasses["_FeatureDef"] = 1;

	retParamName  = "__retVal";

	size_funcs = 0;
	size_classes = 0;
	size_interfaces = 0;
}

function createJavaFileName(clsName_c) {
	return JAVA_GENERATED_SOURCE_DIR "/" myPkgD "/" clsName_c ".java";
}


function printHeader(outFile_h, javaPkg_h, javaClassName_h, isInterface_h,
		implementsInterface_h, isJniBound_h, isAbstract_h, implementsClass_h) {

	if (isInterface_h) {
		classOrInterface_h = "interface";
	} else if (isAbstract_h) {
		classOrInterface_h = "abstract class";
	} else {
		classOrInterface_h = "class";
	}

	extensionsPart_h = "";
	if (isInterface_h) {
		extensionsPart_h = " extends Comparable<" javaClassName_h ">";
	} else if (isAbstract_h) {
		extensionsPart_h = " implements " implementsInterface_h "";
	} else {
		extensionsPart_h = " extends " implementsClass_h " implements " implementsInterface_h;
	}

	printCommentsHeader(outFile_h);
	print("") >> outFile_h;
	print("package " javaPkg_h ";") >> outFile_h;
	print("") >> outFile_h;
	print("") >> outFile_h;
	print("import " myParentPkgA ".AIFloat3;") >> outFile_h;
	if (isJniBound_h) {
		print("import " myMainPkgA ".AICallback;") >> outFile_h;
	}
	print("") >> outFile_h;
	print("/**") >> outFile_h;
	print(" * @author	AWK wrapper script") >> outFile_h;
	print(" * @version	GENERATED") >> outFile_h;
	print(" */") >> outFile_h;
	print("public " classOrInterface_h " " javaClassName_h extensionsPart_h " {") >> outFile_h;
	print("") >> outFile_h;
}


function printTripleFunc(fRet_tr, fName_tr, fParams_tr, outFile_int_tr, outFile_stb_tr, outFile_jni_tr, printIntAndStb_tr) {

	_funcHdr_tr = "public " fRet_tr " " fName_tr "(" fParams_tr ")";
	if (printIntAndStb_tr) {
		print("\t" _funcHdr_tr ";") >> outFile_int_tr;
		print("") >> outFile_int_tr;

		print("\t" "@Override") >> outFile_stb_c;
		print("\t" _funcHdr_tr " {") >> outFile_stb_c;
		if (fRet_tr == "void") {
			# return nothing
		} else if (fRet_tr == "String") {
			print("\t\t" "return \"\";") >> outFile_stb_c;
		} else if (fRet_tr == "boolean") {
			print("\t\t" "return false;") >> outFile_stb_c;
		} else {
			print("\t\t" "return 0;") >> outFile_stb_c;
		}
		print("\t" "}") >> outFile_stb_c;
		print("") >> outFile_stb_c;
	}
	print("\t" "@Override") >> outFile_jni_tr;
	print("\t" _funcHdr_tr " {") >> outFile_jni_tr;
	print("") >> outFile_jni_tr;
}


function printClasses() {

	c_size_cs = cls_id_name["*"];
	for (c=0; c < c_size_cs; c++) {
		cls_cs = cls_id_name[c];
		anc_size_cs = cls_name_implIds[cls_cs ",*"];

		printIntAndStb_cs = 1;
		for (a=0; a < anc_size_cs; a++) {
			implId_cs = cls_name_implIds[cls_cs "," a];
			printClass(implId_cs, cls_cs, printIntAndStb_cs);
			# only print interface and stub when printing the first impl-class
			printIntAndStb_cs = 0;
		}
	}
}


function printClass(implId_c, clsName_c, printIntAndStb_c) {

clsNameExternal_c = clsName_c;

clsId_c = ancestors_c "-" clsName_c;

	implCls_c = implId_c;
	sub(/^.*,/, "", implCls_c);

	clsName_int_c = clsName_c;
	clsName_abs_c = "Abstract" clsName_int_c;
	clsName_stb_c = "Stub" clsName_int_c;
	if (cls_name_implIds[clsName_c ",*"] > 1) {
		lastAncName_c = implId_c;
		sub(/,[^,]*$/, "", lastAncName_c); # remove class name
		sub(/^.*,/,    "", lastAncName_c); # remove pre last ancestor name
		clsName_jni_c = "Wrapp" lastAncName_c implCls_c;
	} else {
		clsName_jni_c = "Wrapp" implCls_c;
	}

#print("print class    : " clsName_jni_c);
if (printIntAndStb_c) {
	#print("print interface: " clsName_int_c);
	#print("print class    : " clsName_stb_c);
}

	if (printIntAndStb_c) {
		outFile_int_c = createJavaFileName(clsName_int_c);
		outFile_abs_c = createJavaFileName(clsName_abs_c);
		outFile_stb_c = createJavaFileName(clsName_stb_c);
#print("Printing interface: "  clsName_int_c);
#print("Printing stub class: " clsName_stb_c);
	}
#print("Printing wrap class: " clsName_jni_c);
	outFile_jni_c = createJavaFileName(clsName_jni_c);

	if (printIntAndStb_c) {
		printHeader(outFile_int_c, myPkgA, clsName_int_c, 1, 0,             0, 0, 0);
		printHeader(outFile_abs_c, myPkgA, clsName_abs_c, 0, clsName_int_c, 0, 1, 0);
		printHeader(outFile_stb_c, myPkgA, clsName_stb_c, 0, clsName_int_c, 0, 0, clsName_abs_c);
	}
	printHeader(    outFile_jni_c, myPkgA, clsName_jni_c, 0, clsName_int_c, 1, 0, clsName_abs_c);

#return;
outFile_c = outFile_jni_c;

	# prepare additional indices names
	addInds_size_c = split(cls_implId_indicesArgs[implId_c], addInds_c, ",");
	for (ai=1; ai <= addInds_size_c; ai++) {
		sub(/int /, "", addInds_c[ai]);
		addInds_c[ai] = trim(addInds_c[ai]);
	}
#if (addInds_size_c != 0) {
#	print("addInds_size_c last: " addInds_size_c " " addInds_c[addInds_size_c]);
#}

	myInnerClb = myClassVar ".getInnerCallback()";


	# print private vars
	print("\t" "private " myWrapClass " " myWrapVar " = null;") >> outFile_c;
	# print additionalVars
	for (ai=1; ai <= addInds_size_c; ai++) {
		print("\t" "private int " addInds_c[ai] " = -1;") >> outFile_c;
	}
	print("") >> outFile_c;


	# print constructor
	ctorParams   = myWrapClass " " myWrapVar;
	addIndPars_c = "";
	for (ai=1; ai <= addInds_size_c; ai++) {
		addIndPars_c = addIndPars_c ", int " addInds_c[ai];
	}
	ctorParams          = ctorParams addIndPars_c;
	ctorParamsNoTypes   = removeParamTypes(ctorParams);
	sub(/^, /, "", addIndPars_c);
	addIndParsNoTypes_c = removeParamTypes(addIndPars_c);
	condAddIndPars_c    = (addIndPars_c == "") ? "" : ", ";
	print("\t" "public " clsName_jni_c "(" ctorParams ") {") >> outFile_c;
	print("") >> outFile_c;
	print("\t\t" "this." myWrapVar " = " myWrapVar ";") >> outFile_c;
	# init additionalVars
	for (ai=1; ai <= addInds_size_c; ai++) {
		addIndName = addInds_c[ai];
		print("\t\t" "this." addIndName " = " addIndName ";") >> outFile_c;
	}
	print("\t" "}") >> outFile_c;
	print("") >> outFile_c;


	# print additional vars fetchers
	for (ai=1; ai <= addInds_size_c; ai++) {
		addIndName = addInds_c[ai];
		_fRet    = "int";
		_fName   = "get" capitalize(addIndName);
		_fParams = "";

		printTripleFunc(_fRet, _fName, _fParams, outFile_int_c, outFile_stb_c, outFile_jni_c, printIntAndStb_c);

		print("\t\t" "return " addIndName ";") >> outFile_jni_c;
		print("\t" "}") >> outFile_jni_c;
		print("") >> outFile_jni_c;
	}

	if (printIntAndStb_c) {
		# print static instance fetcher method
		{
			clsIsBuffered_c = isBufferedClass(clsNameExternal_c);
			fullNameAvailable_c = ancestorsClass_available[clsId_c];

			if (clsIsBuffered_c) {
				print("\t" "private static java.util.Map<Integer, " clsNameExternal_c "> _buffer_instances = new java.util.HashMap<Integer, " clsNameExternal_c ">();") >> outFile_c;
				print("") >> outFile_c;
			}
			print("\t" "static " clsNameExternal_c " getInstance(" ctorParams ") {") >> outFile_c;
			print("") >> outFile_c;
			lastParamName = ctorParamsNoTypes;
			sub(/^.*,[ \t]*/, "", lastParamName);
			if (match(lastParamName, /^[^ \t]+Id$/)) {
				if (clsNameExternal_c == "Unit") {
					# the first valid unit ID is 1
					print("\t\t" "if (" lastParamName " <= 0) {") >> outFile_c;
				} else {
					# ... for all other IDs, the first valid one is 0
					print("\t\t" "if (" lastParamName " < 0) {") >> outFile_c;
				}
				print("\t\t\t" "return null;") >> outFile_c;
				print("\t\t" "}") >> outFile_c;
				print("") >> outFile_c;
			}
			print("\t\t" clsNameExternal_c " _ret = null;") >> outFile_c;
			if (fullNameAvailable_c == "") {
				print("\t\t" "_ret = new " clsName_jni_c "(" ctorParamsNoTypes ");") >> outFile_c;
			} else {
				print("\t\t" "boolean isAvailable = " myWrapVar ".getInnerCallback()." fullNameAvailable_c "(" addIndParsNoTypes_c ");") >> outFile_c;
				print("\t\t" "if (isAvailable) {") >> outFile_c;
				print("\t\t\t" "_ret = new " clsName_jni_c "(" ctorParamsNoTypes ");") >> outFile_c;
				print("\t\t" "}") >> outFile_c;
			}
			if (clsIsBuffered_c) {
				if (fullNameAvailable_c == "") {
					print("\t\t" "{") >> outFile_c;
				} else {
					print("\t\t" "if (_ret != null) {") >> outFile_c;
				}
				print("\t\t\t" "Integer indexHash = _ret.hashCode();") >> outFile_c;
				print("\t\t\t" "if (_buffer_instances.containsKey(indexHash)) {") >> outFile_c;
				print("\t\t\t\t" "_ret = _buffer_instances.get(indexHash);") >> outFile_c;
				print("\t\t\t" "} else {") >> outFile_c;
				print("\t\t\t\t" "_buffer_instances.put(indexHash, _ret);") >> outFile_c;
				print("\t\t\t" "}") >> outFile_c;
				print("\t\t" "}") >> outFile_c;
			}
			print("\t\t" "return _ret;") >> outFile_c;
			print("\t" "}") >> outFile_c;
			print("") >> outFile_c;
		}


		# print compareTo(other) method
		{
			print("\t" "@Override") >> outFile_abs_c;
			print("\t" "public int compareTo(" clsNameExternal_c " other) {") >> outFile_abs_c;
			print("\t\t" "final int BEFORE = -1;") >> outFile_abs_c;
			print("\t\t" "final int EQUAL  =  0;") >> outFile_abs_c;
			print("\t\t" "final int AFTER  =  1;") >> outFile_abs_c;
			print("") >> outFile_abs_c;
			print("\t\t" "if (this == other) return EQUAL;") >> outFile_abs_c;
			print("") >> outFile_abs_c;

			if (isClbRootCls) {
				print("\t\t" "if (this.skirmishAIId < other.skirmishAIId) return BEFORE;") >> outFile_abs_c;
				print("\t\t" "if (this.skirmishAIId > other.skirmishAIId) return AFTER;") >> outFile_abs_c;
				print("\t\t" "return EQUAL;") >> outFile_abs_c;
			} else {
				for (ai=1; ai <= addInds_size_c; ai++) {
					addIndName = addInds_c[ai];
					print("\t\t" "if (this.get" capitalize(addIndName) "() < other.get" capitalize(addIndName) "()) return BEFORE;") >> outFile_abs_c;
					print("\t\t" "if (this.get" capitalize(addIndName) "() > other.get" capitalize(addIndName) "()) return AFTER;") >> outFile_abs_c;
				}
				print("\t\t" "return 0;") >> outFile_abs_c;
			}
			print("\t" "}") >> outFile_abs_c;
			print("") >> outFile_abs_c;
		}


		# print equals(other) method
		if (!isClbRootCls) {
			print("\t" "@Override") >> outFile_abs_c;
			print("\t" "public boolean equals(Object otherObject) {") >> outFile_abs_c;
			print("") >> outFile_abs_c;
			print("\t\t" "if (this == otherObject) return true;") >> outFile_abs_c;
			print("\t\t" "if (!(otherObject instanceof " clsNameExternal_c ")) return false;") >> outFile_abs_c;
			print("\t\t" clsNameExternal_c " other = (" clsNameExternal_c ") otherObject;") >> outFile_abs_c;
			print("") >> outFile_abs_c;

			if (isClbRootCls) {
				print("\t\t" "if (this.skirmishAIId != other.skirmishAIId) return false;") >> outFile_abs_c;
				print("\t\t" "return true;") >> outFile_abs_c;
			} else {
				for (ai=1; ai <= addInds_size_c; ai++) {
					addIndName = addInds_c[ai];
					print("\t\t" "if (this.get" capitalize(addIndName) "() != other.get" capitalize(addIndName) "()) return false;") >> outFile_abs_c;
				}
				print("\t\t" "return true;") >> outFile_abs_c;
			}
			print("\t" "}") >> outFile_abs_c;
			print("") >> outFile_abs_c;
		}


		# print hashCode() method
		if (!isClbRootCls) {
			print("\t" "@Override") >> outFile_abs_c;
			print("\t" "public int hashCode() {") >> outFile_abs_c;
			print("") >> outFile_abs_c;

			if (isClbRootCls) {
				print("\t\t" "int _res = 0;") >> outFile_abs_c;
				print("") >> outFile_abs_c;
				print("\t\t" "_res += this.skirmishAIId * 10E8;") >> outFile_abs_c;
			} else {
				print("\t\t" "int _res = 23;") >> outFile_abs_c;
				print("") >> outFile_abs_c;
				# NOTE: This could go wrong if we have more then 7 additional indices
				# see 10E" (7-ai) below
				# the conversion to int is nessesarry,
				# as otherwise it would be a double,
				# which would be higher then max int,
				# and most hashes would end up being max int,
				# when converted from double to int
				for (ai=1; ai <= addInds_size_c; ai++) {
					addIndName = addInds_c[ai];
					print("\t\t" "_res += this.get" capitalize(addIndName) "() * (int) (10E" (7-ai) ");") >> outFile_abs_c;
				}
			}
			print("") >> outFile_abs_c;
			print("\t\t" "return _res;") >> outFile_abs_c;
			print("\t" "}") >> outFile_abs_c;
			print("") >> outFile_abs_c;
		}


		# print toString() method
		{
			print("\t" "@Override") >> outFile_abs_c;
			print("\t" "public String toString() {") >> outFile_abs_c;
			print("") >> outFile_abs_c;
			print("\t\t" "String _res = this.getClass().toString();") >> outFile_abs_c;
			print("") >> outFile_abs_c;

			#if (isClbRootCls) {
			#	print("\t\t" "_res = _res + \"(skirmishAIId=\" + this.skirmishAIId + \", \";") >> outFile_abs_c;
			#} else {
			#	print("\t\t" "_res = _res + \"(clbHash=\" + this." myWrapVar ".hashCode() + \", \";") >> outFile_abs_c;
			#	print("\t\t" "_res = _res + \"skirmishAIId=\" + this." myWrapVar ".SkirmishAI_getSkirmishAIId() + \", \";") >> outFile_abs_c;
				for (ai=1; ai <= addInds_size_c; ai++) {
					addIndName = addInds_c[ai];
					print("\t\t" "_res = _res + \"" addIndName "=\" + this.get" capitalize(addIndName) "() + \", \";") >> outFile_abs_c;
				}
			#}
			print("\t\t" "_res = _res + \")\";") >> outFile_abs_c;
			print("") >> outFile_abs_c;
			print("\t\t" "return _res;") >> outFile_abs_c;
			print("\t" "}") >> outFile_abs_c;
			print("") >> outFile_abs_c;
		}
	}

	# make these available in called functions
	implId_c_         = implId_c;
	clsName_c_        = clsName_c;
	printIntAndStb_c_ = printIntAndStb_c;

	# print member functions
	members_size = cls_name_members[clsName_int_c ",*"];
#print("mems " clsName_int_c ": " members_size);
	for (m=0; m < members_size; m++) {
		memName_c  = cls_name_members[clsName_int_c "," m];
		fullName_c = implId_c "," memName_c;
		gsub(/,/, "_", fullName_c);
		if (doWrapp(fullName_c)) {
			printMember(fullName_c, memName_c, addInds_size_c);
		}
	}


	# print member class fetchers (single, multi, multi-fetch-single)
	size_memCls = split(ancestors_class[clsFull_c], memCls, ",");
	for (mc=0; mc < size_memCls; mc++) {
		memberClass_c = memCls[mc+1];
		#printMemberClassFetchers(clsFull_c, clsId_c, memberClass_c, isInterface_c);
	}


	# finnish up
	if (printIntAndStb_c) {
		print("}") >> outFile_int_c;
		print("") >> outFile_int_c;
		close(outFile_int_c);

		print("}") >> outFile_abs_c;
		print("") >> outFile_abs_c;
		close(outFile_abs_c);

		print("}") >> outFile_stb_c;
		print("") >> outFile_stb_c;
		close(outFile_stb_c);
	}
	print("}") >> outFile_jni_c;
	print("") >> outFile_jni_c;
	close(outFile_jni_c);
}

function printMemberClassFetchers(outFile_mc, clsFull_mc, clsId_mc, memberClsName_mc, isInterface_mc) {

		memberClassId_mc = clsFull_mc "-" memberClsName_mc;
		size_multi_mc = ancestorsClass_multiSizes[memberClassId_mc "*"];
		isMulti_mc = (size_multi_mc != "");
		if (isMulti_mc) {
			# multi element fetcher(s)
			for (mmc=0; mmc < size_multi_mc; mmc++) {
				fullNameMultiSize_mc = ancestorsClass_multiSizes[memberClassId_mc "#" mmc];
				printMemberClassFetcher(outFile_mc, clsFull_mc, clsId_mc, memberClsName_mc, isInterface_mc, fullNameMultiSize_mc);
			}
		} else {
			# single element fetcher
			printMemberClassFetcher(outFile_mc, clsFull_mc, clsId_mc, memberClsName_mc, isInterface_mc, 0);
		}
}
# fullNameMultiSize_mf is 0 if it is no multi element
function printMemberClassFetcher(outFile_mf, clsFull_mf, clsId_mf, memberClsName_mf, isInterface_mf, fullNameMultiSize_mf) {

		memberClassId_mf = clsFull_mf "-" memberClsName_mf;
		isMulti_mf = fullNameMultiSize_mf != 0;
		if (interfaces[memberClsName_mf] != "") {
			memberClassImpl_mf = implClsNames[memberClassId_mf];
		} else {
			memberClassImpl_mf = memberClsName_mf;
		}
		if (isMulti_mf) {
			# multi element fetcher
			if (match(fullNameMultiSize_mf, /^.*0MULTI1[^0]*3/)) {
				# wants a different function name then the default one
				fn = fullNameMultiSize_mf;
				sub(/^.*0MULTI1[^3]*3/, "", fn); # remove pre MULTI 3
				sub(/[0-9].*$/, "", fn); # remove post MULTI 3
			} else {
				fn = memberClsName_mf "s";
			}
			fn = "get" fn;

			params = funcParams[fullNameMultiSize_mf];
			innerParams = funcInnerParams[fullNameMultiSize_mf];

			fullNameMultiVals_mf = fullNameMultiSize_mf;
			sub(/0MULTI1SIZE/, "0MULTI1VALS", fullNameMultiVals_mf);
			hasMultiVals_mf = (funcRetType[fullNameMultiVals_mf] != "");
		} else {
			# single element fetcher
			fn = "get" memberClsName_mf;
			params = "";
		}

		# remove additional indices from params
		for (ai=0; ai < addInds_size_c; ai++) {
			sub(/int [_a-zA-Z0-9]+(, )?/, "", params);
		}

		retType = memberClsName_mf;
		if (isMulti_mf) {
			retTypeInterface = "java.util.List<" retType ">";
			retType = "java.util.ArrayList<" retType ">";
		} else {
			retTypeInterface = retType;
		}
		condInnerParamsComma = (innerParams == "") ? "" : ", ";

		# concatenate additional indices
		indexParams_mf = "";
		for (ai=0; ai < addInds_size_c; ai++) {
			addIndName = additionalClsIndices[clsId_mf "#" ai];
			indexParams_mf = indexParams_mf  ", " addIndName;
		}
		sub(/^\, /, "", indexParams_mf); # remove comma at the end
		condIndexComma_mf = (indexParams_mf == "") ? "" : ", ";

		indent_mf = "\t";

		print("") >> outFile_mf;

		isBuffered_mf = isBufferedFunc(clsFull_mf "_" memberClsName_mf) && (params == "");
		if (!isInterface_mf && isBuffered_mf) {
			print(indent_mf "private " retType " _buffer_" fn ";") >> outFile_mf;
			print(indent_mf "private boolean _buffer_isInitialized_" fn " = false;") >> outFile_mf;
		}

		printFunctionComment_Common(outFile_mf, funcDocComment, fullNameMultiSize_mf, indent_mf);

		print(indent_mf "public " retTypeInterface " " fn "(" params ") {") >> outFile_mf;
		print("") >> outFile_mf;
		indent_mf = indent_mf "\t";
		if (isBuffered_mf) {
			print(indent_mf retType " _ret = _buffer_" fn ";") >> outFile_mf;
			print(indent_mf "if (!_buffer_isInitialized_" fn ") {") >> outFile_mf;
			indent_mf = indent_mf "\t";
		} else {
			print(indent_mf retType " _ret;") >> outFile_mf;
		}
		if (isMulti_mf) {
			print(indent_mf "int size = " myWrapVar "." fullNameMultiSize_mf "(" mySkirmishAIId condInnerParamsComma innerParams ");") >> outFile_mf;
			if (hasMultiVals_mf) {
				print(indent_mf "int[] tmpArr = new int[size];") >> outFile_mf;
				print(indent_mf myWrapVar "." fullNameMultiVals_mf "(" mySkirmishAIId condInnerParamsComma innerParams ", tmpArr, size);") >> outFile_mf;
				print(indent_mf retType " arrList = new " retType "(size);") >> outFile_mf;
				print(indent_mf "for (int i=0; i < size; i++) {") >> outFile_mf;
				print(indent_mf "\t" "arrList.add(" memberClassImpl_mf ".getInstance(" myClassVarLocal condIndexComma_mf indexParams_mf ", tmpArr[i]));") >> outFile_mf;
				print(indent_mf "}") >> outFile_mf;
				print(indent_mf "_ret = arrList;") >> outFile_mf;
			} else {
				print(indent_mf retType " arrList = new " retType "(size);") >> outFile_mf;
				print(indent_mf "for (int i=0; i < size; i++) {") >> outFile_mf;
				print(indent_mf "\t" "arrList.add(" memberClassImpl_mf ".getInstance(" myClassVarLocal condIndexComma_mf indexParams_mf ", i));") >> outFile_mf;
				print(indent_mf "}") >> outFile_mf;
				print(indent_mf "_ret = arrList;") >> outFile_mf;
			}
		} else {
			print(indent_mf "_ret = " memberClassImpl_mf ".getInstance(" myClassVarLocal condIndexComma_mf indexParams_mf ");") >> outFile_mf;
		}
		if (isBuffered_mf) {
			print(indent_mf "_buffer_" fn " = _ret;") >> outFile_mf;
			print(indent_mf "_buffer_isInitialized_" fn " = true;") >> outFile_mf;
			sub(/\t/, "", indent_mf);
			print(indent_mf "}") >> outFile_mf;
			print("") >> outFile_mf;
		}
		print(indent_mf "return _ret;") >> outFile_mf;
		sub(/\t/, "", indent_mf);
		print("\t" "}") >> outFile_mf;
}



function isRetParamName(paramName_rp) {
	return (match(paramName_rp, /_out(_|$)/) || match(paramName_rp, /(^|_)?ret_/));
}

# UNUSED
function cleanRetParamName(paramName_rp) {

	paramNameClean_rp = paramName_rp;

	sub(/_out(_|$)/,  "", paramNameClean_rp);
	sub(/(^|_)?ret_/, "", paramNameClean_rp);

	return paramNameClean_rp;
}

function printMember(fullName_m, memName_m, additionalIndices_m) {
#print("Printing member: " fullName_m);
	# use some vars from the printClass function (which called us)
	implId_m         = implId_c_;
	clsName_m        = clsName_c_;
	printIntAndStb_m = printIntAndStb_c_;
	implCls_m        = implCls_c;
	clsName_int_m    = clsName_int_c;
	clsName_stb_m    = clsName_stb_c;
	clsName_jni_m    = clsName_jni_c;
	outFile_int_m    = outFile_int_c;
	outFile_stb_m    = outFile_stb_c;
	outFile_jni_m    = outFile_jni_c;

	indent_m            = "\t";
	memId_m             = clsName_m "," memName_m;
	retType             = cls_memberId_retType[memId_m];
	retType_int         = "";
	params              = cls_memberId_params[memId_m];
	isFetcher           = cls_memberId_isFetcher[memId_m];
	metaComment         = cls_memberId_metaComment[memId_m];
#print("retType: " retType);
	innerParams         = removeParamTypes(params);
	memName             = fullName_m;
	sub(/^.*_/, "", memName);
	isVoid_m            = (retType == "void");
	conversionCode_pre  = "";
	conversionCode_post = "";

outFile_m = outFile_jni_m;

	# convert param types
	paramNames_size = split(innerParams, paramNames, ", ");
	for (prm = 1; prm <= paramNames_size; prm++) {
		paNa = paramNames[prm];
		if (!isRetParamName(paNa)) {
			if (match(paNa, /_posF3/)) {
				# convert float[3] to AIFloat3
				paNaNew = paNa;
				sub(/_posF3/, "", paNaNew);
				sub("float\\[\\] " paNa, "AIFloat3 " paNaNew, params);
				conversionCode_pre = conversionCode_pre "\t\t"  "float[] " paNa " = " paNaNew ".toFloatArray();" "\n";
			} else if (match(paNa, /_colorS3/)) {
				# convert short[3] to java.awt.Color
				paNaNew = paNa;
				sub(/_colorS3/, "", paNaNew);
				sub("short\\[\\] " paNa, "java.awt.Color " paNaNew, params);
				conversionCode_pre = conversionCode_pre "\t\t"  "short[] " paNa " = Util.toShort3Array(" paNaNew ");" "\n";
			}
		}
	}

	# convert out params to return values
	#metaComment "error-return:0=OK"
	paramTypeNames_size = split(params, paramTypeNames, ", ");
	hasRetParam = 0;
	for (prm = 1; prm <= paramTypeNames_size; prm++) {
		paNa = extractParamName(paramTypeNames[prm]);
		if (isRetParamName(paNa)) {
			paTy = extractParamType(paramTypeNames[prm]);
			hasRetParam = 1;
			if (match(paNa, /_posF3/)) {
				# convert float[3] to AIFloat3
				retParamType = "AIFloat3";
				conversionCode_pre  = conversionCode_pre  "\t\t" "float[] " paNa " = new float[3];" "\n";
				conversionCode_post = conversionCode_post "\t\t" retParamType " _ret = new AIFloat3(" paNa ");" "\n";
				sub("(, )?float\\[\\] " paNa, "", params);
			} else if (match(paNa, /_colorS3/)) {
				retParamType = "java.awt.Color";
				conversionCode_pre  = conversionCode_pre  "\t\t" "short[] " paNa " = new short[3];" "\n";
				conversionCode_post = conversionCode_post "\t\t" retParamType " _ret = Util.toShort3Array(" paNa ");" "\n";
				sub("(, )?short\\[\\] " paNa, "", params);
			} else {
				print("FAILED converting return param: " paramTypeNames[prm] " / " fullName_m);
				exit(-1);
			}
#print(paNa);
		}
	}

	isArray = part_isArray(fullName_m, metaComment);
#print("metaComment: " metaComment);
	if (isArray) {
print("isArray::fullName_m: " fullName_m);
		fullNameArraySize = fullName_m;

		sub(/\, int [_a-zA-Z0-9]+$/, "", params); # remove max
		arrayType = params; # getArrayType
		sub(/^.*\, /, "", arrayType); # remove pre array type
		hadBraces = sub(/\[\] .*$/, "", arrayType); # remove post array type
		if (!hadBraces) {
			sub(/[^ \t]*$/, "", arrayType); # remove param name
		}
		referenceType = arrayType;
		if (match(fullNameArraySize, /0ARRAY1SIZE1/)) {
			# we want to reference objects, of a certain class as arrayType
			referenceType = fullNameArraySize;
			sub(/^.*0ARRAY1SIZE1/, "", referenceType); # remove pre ref array type
			sub(/[0123].*$/, "", referenceType); # remove post ref array type
		}
		arrType_java = convertJavaBuiltinTypeToClass(referenceType);
		retType_int = "java.util.List<" arrType_java ">";
		retType = "java.util.ArrayList<" arrType_java ">";
		sub(/(\, )?[^ ]+ [_a-zA-Z0-9]+$/, "", params); # remove array
	}

	isMap = part_isMap(fullName_m, metaComment);
	if (isMap) {
print("isMap::fullName_m: " fullName_m);
		fullNameMapSize = fullName_m;

		fullNameMapKeys = fullNameMapSize;
		sub(/0MAP1SIZE/, "0MAP1KEYS", fullNameMapKeys);
		keyType = funcParams[fullNameMapKeys];
		sub(/\[\].*$/, "", keyType); # remove everything after array type
		sub(/^.* /, "", keyType); # remove everything before array type

		fullNameMapVals = fullNameMapSize;
		sub(/0MAP1SIZE/, "0MAP1VALS", fullNameMapVals);
		valType = funcParams[fullNameMapVals];
		sub(/\[\].*$/, "", valType); # remove everything after array type
		sub(/^.* /, "", valType); # remove everything before array type

		sub(/\, int [_a-zA-Z0-9]+$/, "", params); # remove max
		retType = "java.util.Map<" convertJavaBuiltinTypeToClass(keyType) ", " convertJavaBuiltinTypeToClass(valType) ">"; # getArrayType
		sub(/\, [^ ]+ [_a-zA-Z0-9]+$/, "", params); # remove array
	}

	isSingleFetch = part_isSingleFetch(fullName_m, metaComment);
	if (isSingleFetch) {
print("isSingleFetch::fullName_m: " fullName_m);
		fetchClass_m = fullName_m;
		sub(/0[^0]*$/, "", fetchClass_m); # remove everything after array type
		sub(/.*0SINGLE1FETCH[^2]*2/, "", fetchClass_m); # remove everything before array type
		innerRetType = retType;
		retType = fetchClass_m;

		indName_m = additionalClsIndices[clsId_c "#" (additionalClsIndices[clsId_c "*"]-1)];
		instanceInnerParams = "";
	}

	refObjsFullName_m = fullName_m;
	hasReferenceObject_m = part_hasReferenceObject(refObjsFullName_m);
	while (hasReferenceObject_m) {
		refObj_m = refObjsFullName_m;
		sub(/^.*0REF/, "", refObj_m); # remove everything before ref type
		sub(/0.*$/, "", refObj_m); # remove everything after ref type

		refCls_m = refObj_m;
		sub(/^[^1]*1/, "", refCls_m); # remove everything before ref cls
		sub(/[123].*$/, "", refCls_m); # remove everything after ref cls

		refParamName_m = refObj_m;
		sub(/^[^2]*2/, "", refParamName_m); # remove everything before ref param name
		sub(/[123].*$/, "", refParamName_m); # remove everything after ref param name

		sub("int " refParamName_m, refCls_m " c_" refParamName_m, params); # remove everything before ref param name
		sub(refParamName_m, "c_" refParamName_m ".get" capitalize(refParamName_m) "()", innerParams); # remove everything before ref param name

		sub("0REF" refObj_m, "", refObjsFullName_m); # remove everything after array type
		hasReferenceObject_m = part_hasReferenceObject(refObjsFullName_m);
	}

	# remove additional indices from params
	for (ai=0; ai < additionalIndices_m; ai++) {
		sub(/int [_a-zA-Z0-9]+(, )?/, "", params);
	}

	firstLineEnd = ";";
	mod_m = "";
	if (!isInterface_m) {
		firstLineEnd = " {";
		mod_m = "public ";
	}

	retTypeInterface = trim(retType);
	#if (retTypeInterface == "") {
	#	retTypeInterface = retType;
	#}
#print("retType: " retType);
#print("retTypeInterface: " retTypeInterface);

	print("") >> outFile_m;

	isBuffered_m = !isVoid_m && isBufferedFunc(fullName_m) && (params == "");
	if (!isInterface_m && isBuffered_m) {
		print(indent_m retType " _buffer_" memName ";") >> outFile_m;
		print(indent_m "boolean _buffer_isInitialized_" memName " = false;") >> outFile_m;
	}

	# print method doc comment
	if (printIntAndStb_m) {
		printFunctionComment_Common(outFile_int_m, funcDocComment, fullName_m, indent_m);
		printFunctionComment_Common(outFile_stb_m, funcDocComment, fullName_m, indent_m);
	}
	printFunctionComment_Common(outFile_jni_m, funcDocComment, fullName_m, indent_m);

	#print(indent_m mod_m retTypeInterface " " memName "(" params ")" firstLineEnd) >> outFile_m;
	printTripleFunc(retTypeInterface, memName, params, outFile_int_m, outFile_stb_m, outFile_jni_m, printIntAndStb_m);
	
	if (!isInterface_m) {
		condRet = isVoid_m ? "" : "_ret = ";
		indent_m = indent_m "\t";
		if (memName == "handleCommand") {
			print(indent_m "command.write();") >> outFile_m;
		}
		if (isBuffered_m) {
			print(indent_m retType " _ret = _buffer_" memName ";") >> outFile_m;
			print(indent_m "if (!_buffer_isInitialized_" memName ") {") >> outFile_m;
			indent_m = indent_m "\t";
		} else if (!isVoid_m) {
			print(indent_m retType " _ret;") >> outFile_m;
		}
		if (conversionCode_pre != "") {
			print(conversionCode_pre) >> outFile_m;
		}
		if (hasRetParam) {
			print("") >> outFile_m;
			print(indent_m retParamType " " retParamName " = new float[3];") >> outFile_m;
		}
		if (isArray) {
			print("") >> outFile_m;
			print(indent_m "int size = " myWrapVar "." fullNameArraySize "("innerParams ");") >> outFile_m;
			print(indent_m retType " arrList = new " retType "(size);") >> outFile_m;
			print(indent_m "if (size > 0) {") >> outFile_m;
			indent_m = indent_m "\t";
			print(indent_m arrayType "[] tmpArr = new " arrayType "[size];") >> outFile_m;
			print(indent_m myWrapVar "." fullNameArrayVals "(" innerParams ", tmpArr, size);") >> outFile_m;
			print(indent_m "for (int i=0; i < size; i++) {") >> outFile_m;
			indent_m = indent_m "\t";
			if (arrayType == referenceType) {
				print(indent_m "arrList.add(tmpArr[i]);") >> outFile_m;
			} else {
				print(indent_m "arrList.add(" referenceType ".getInstance(" myClassVarLocal ", tmpArr[i]));") >> outFile_m;
			}
			sub(/\t/, "", indent_m);
			print(indent_m "}") >> outFile_m;
			sub(/\t/, "", indent_m);
			print(indent_m "}") >> outFile_m;
			print(indent_m "_ret = arrList;") >> outFile_m;
		} else if (isMap) {
			print("") >> outFile_m;
			print(indent_m "int size = " myWrapVar "." fullNameMapSize "(" innerParams ");") >> outFile_m;
			retMapImplType = retType;
			sub(/Map/, defMapJavaImpl, retMapImplType);
			print(indent_m retType " retMap = new " retMapImplType "(size);") >> outFile_m;
			print(indent_m "if (size > 0) {") >> outFile_m;
			indent_m = indent_m "\t";
			print(indent_m keyType "[] tmpKeysArr = new " keyType "[size];") >> outFile_m;
			print(indent_m myWrapVar "." fullNameMapKeys "(" innerParams ", tmpKeysArr);") >> outFile_m;
			print(indent_m valType "[] tmpValsArr = new " valType "[size];") >> outFile_m;
			print(indent_m myWrapVar "." fullNameMapVals "(" innerParams ", tmpValsArr);") >> outFile_m;
			print(indent_m "for (int i=0; i < size; i++) {") >> outFile_m;
			print(indent_m "\t" "retMap.put(tmpKeysArr[i], tmpValsArr[i]);") >> outFile_m;
			print(indent_m "}") >> outFile_m;
			sub(/\t/, "", indent_m);
			print(indent_m "}") >> outFile_m;
			print(indent_m "_ret = retMap;") >> outFile_m;
		} else if (isSingleFetch) {
			condInstanceInnerParamsComma = (instanceInnerParams == "") ? "" : ", ";
			print("") >> outFile_m;
			print(indent_m innerRetType " innerRet = " myWrapVar "." fullName_m "(" innerParams ");") >> outFile_m;
			print(indent_m "_ret = " retType ".getInstance(" myClassVarLocal ", innerRet" condInstanceInnerParamsComma instanceInnerParams ");") >> outFile_m;
		} else {
			print(indent_m condRet myWrapVar "." fullName_m "(" innerParams ");") >> outFile_m;
		}
		if (conversionCode_post != "") {
			print(conversionCode_post) >> outFile_m;
		}
		if (hasRetParam) {
			#if (isBuffered_m) { # NO FOLD
			#	print(indent_m "_ret = new AIFloat3(" retParamName ");") >> outFile_m;
			#} else { # NO FOLD
			#	print(indent_m "return new AIFloat3(" retParamName ");") >> outFile_m;
			#}
			#print(indent_m "return _ret;") >> outFile_m;
		}
		if (isBuffered_m) {
			print(indent_m "_buffer_" memName " = _ret;") >> outFile_m;
			print(indent_m "_buffer_isInitialized_" memName " = true;") >> outFile_m;
			sub(/\t/, "", indent_m);
			print(indent_m "}") >> outFile_m;
			print("") >> outFile_m;
		}
		if (memName == "handleCommand") {
			print(indent_m "command.read();") >> outFile_m;
		}
		if (!isVoid_m) {
			print(indent_m "return _ret;") >> outFile_m;
		}
		sub(/\t/, "", indent_m);
		print(indent_m "}") >> outFile_m;
	}
}


# Used by the common OO AWK script
function doWrapp(funcFullName_dw, params_dw, metaComment_dw) {

	doWrapp_dw = 1;

	doWrapp_dw = doWrapp_dw && !match(params_dw, /String\[\]/);
	doWrapp_dw = doWrapp_dw && !match(funcFullName_dw, /Lua_callRules/);

	return doWrapp_dw;
}

function wrappFunctionDef(funcDef, commentEolTot) {

	size_funcParts = split(funcDef, funcParts, "(\\()|(\\)\\;)");
	# because the empty part after ");" would count as part as well
	size_funcParts--;

	fullName = funcParts[1];
	fullName = trim(fullName);
	sub(/.*[ \t]+/, "", fullName);

	retType = funcParts[1];
	sub(/[ \t]*public/, "", retType);
	sub(fullName, "", retType);
	retType = trim(retType);

	params = funcParts[2];

	wrappFunctionPlusMeta(retType, fullName, params, commentEolTot);
}

# This function has to return true (1) if a doc comment (eg: /** foo bar */)
# can be deleted.
# If there is no special condition you want to apply,
# it should always return true (1),
# cause there are additional mechanism to prevent accidential deleting.
# see: commonDoc.awk
function canDeleteDocumentation() {
	return isMultiLineFunc != 1;
}


# grab callback functions info
# 2nd, 3rd, ... line of a function definition
{
	if (isMultiLineFunc) { # function is defined on one single line
		funcIntermLine = $0;
		# separate possible comment at end of line: // fu bar
		commentEol = funcIntermLine;
		if (sub(/.*\/\//, "", commentEol)) {
			commentEolTot = commentEolTot commentEol;
		}
		sub(/[ \t]*\/\/.*$/, "", funcIntermLine);
		funcIntermLine = trim(funcIntermLine);
		funcSoFar = funcSoFar " " funcIntermLine;
		if (match(funcSoFar, /\;$/)) {
			# function ends in this line
			wrappFunctionDef(funcSoFar, commentEolTot);
			isMultiLineFunc = 0;
		}
	}
}
# 1st line of a function definition
/\tpublic .*);/ {

	funcStartLine = $0;
	# separate possible comment at end of line: // foo bar
	commentEolTot = "";
	commentEol = funcStartLine;
	if (sub(/.*\/\//, "", commentEol)) {
		commentEolTot = commentEolTot commentEol;
	}
	# remove possible comment at end of line: // foo bar
	sub(/\/\/.*$/, "", funcStartLine);
	funcStartLine = trim(funcStartLine);
	if (match(funcStartLine, /\;$/)) {
		# function ends in this line
		wrappFunctionDef(funcStartLine, commentEolTot);
	} else {
		funcSoFar = funcStartLine;
		isMultiLineFunc = 1;
	}
}



END {
	# finalize things
	store_everything();
	printClasses();
}