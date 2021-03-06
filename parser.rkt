(module parser racket
  (provide (all-defined-out))

  (require parser-tools/yacc
           "lexer.rkt")

  ; Assignment operators
  (define no__op_assgn 'no__op_assgn)
  (define mul_op_assgn 'mul_op_assgn)
  (define div_op_assgn 'div_op_assgn)
  (define mod_op_assgn 'mod_op_assgn)
  (define add_op_assgn 'add_op_assgn)
  (define sub_op_assgn 'sub_op_assgn)
  (define lef_op_assgn 'lef_op_assgn)
  (define rig_op_assgn 'rig_op_assgn)
  (define and_op_assgn 'and_op_assgn)
  (define xor_op_assgn 'xor_op_assgn)
  (define or__op_assgn 'or__op_assgn)

  ; Unary operators
  (define adrop 'adrop)
  (define ptrop 'ptrop)
  (define valop 'valop)
  (define negop 'negop)
  (define comop 'comop)
  (define notop 'notop)

  ; Control flow
  (define func 'func)
  (define defi 'defi)
  (define var_ 'var_)
  (define decl 'decl)
  (define skip 'skip)
  (define cast 'cast)
  (define func_call 'func_call)
  (define expr 'expr)

  ; Arithmetic operators
  (define mulop 'mulop)
  (define divop 'divop)
  (define modop 'modop)
  (define addop 'addop)
  (define subop 'subop)
  (define lefop 'lefop)
  (define rigop 'rigop)
  (define lesop 'lesop)
  (define greop 'greop)
  (define leqop 'leqop)
  (define geqop 'geqop)
  (define equop 'equop)
  (define neqop 'neqop)
  (define ampop 'ampop)
  (define xorop 'xorop)
  (define pipop 'pipop)
  (define andop 'andop)
  (define or_op 'or_op)
  (define terop 'terop)

  ; Hash for arithmetic operator assignments to operators
  (define op-hash 
    (make-hash '((mul_op_assgn . mulop)
                 (div_op_assgn . divop)
                 (mod_op_assgn . modop)
                 (add_op_assgn . addop)
                 (sub_op_assgn . subop)
                 (lef_op_assgn . lefop)
                 (rig_op_assgn . rigop)
                 (and_op_assgn . andop)
                 (xor_op_assgn . xorop)
                 (or__op_assgn . or_op))))

  ; Basic types
  (define voitype  'voitype)
  (define chatype  'chatype)
  (define shotype  'shotype)
  (define inttype  'inttype)
  (define lontype  'lontype)
  (define flotype  'flotype)
  (define doutype  'doutype)
  (define sigtype  'sigtype)
  (define unstype  'unstype)

  (define identf 'identf)
  (define constn 'constn)
  (define return 'return)

  ; Some macros

  (define-syntax-rule (assgn op op1 op2)
                      (if (equal? op no__op_assgn)
                        (tree 'assgn op1 op2)
                        (tree 'assgn op1 (tree (hash-ref op-hash op) op1 op2))))

  (define-syntax tree 
    (syntax-rules ()
      [(tree a) (list a)]
      [(tree a b ...) (list a (list b ...))]))

  (define objc-parser
    (parser
      (start exp)
      (end EOF)
      (error void)
      (tokens value-tokens op)
      (suppress)
      (grammar
        (exp 
          ((translation_unit) $1))

        (primary_expression 
          ((identifier       ) (list identf $1 ))
          ((CONSTANT         ) (list constn $1 ))
          ((STRING_LITERAL   ) #f              )
          ((LB expression RB ) $2              ))

        (postfix_expression
          ((primary_expression                                ) $1 )
          ((postfix_expression LSB expression RSB             ) #f )
          ((postfix_expression LB RB                          ) (list func_call $1 null))
          ((postfix_expression LB argument_expression_list RB ) (list func_call $1 $3))
          ((postfix_expression DOT identifier                 ) #f )
          ((postfix_expression PTR_OP identifier              ) #f )
          ((postfix_expression INC_OP                         ) (assgn add_op_assgn $1 '(constn "1")))
          ((postfix_expression DEC_OP                         ) #f ))

        (argument_expression_list 
          ((assignment_expression                                ) (list $1))
          ((argument_expression_list COMMA assignment_expression ) (append $1 (list $3))))

        (unary_expression
          ((postfix_expression             ) $1 )
          ((INC_OP unary_expression        ) #f )
          ((DEC_OP unary_expression        ) #f )
          ((unary_operator cast_expression ) #f )
          ((SIZEOF unary_expression        ) #f )
          ((SIZEOF LB type_name RB         ) #f ))

        (unary_operator 
          ((AMPERSAND   ) adrop )
          ((ASTERISK    ) ptrop )
          ((PLUS        ) valop )
          ((MINUS       ) negop )
          ((TILDE       ) comop )
          ((EXCLAMATION ) notop ))

        (cast_expression 
          ((unary_expression                ) $1               )
          ((LB type_name RB cast_expression ) (tree cast $2 $4 )))

        (multiplicative_expression
          ((cast_expression                                    ) $1                )
          ((multiplicative_expression ASTERISK cast_expression ) (tree mulop $1 $3 ))
          ((multiplicative_expression DIV cast_expression      ) (tree divop $1 $3 ))
          ((multiplicative_expression MODULO cast_expression   ) (tree modop $1 $3 )))

        (additive_expression 
          ((multiplicative_expression                           ) $1                )
          ((additive_expression PLUS multiplicative_expression  ) (tree addop $1 $3 ))
          ((additive_expression MINUS multiplicative_expression ) (tree subop $1 $3 )))

        (shift_expression 
          ((additive_expression                           ) $1                )
          ((shift_expression LEFT_OP additive_expression  ) (tree lefop $1 $3 ))
          ((shift_expression RIGHT_OP additive_expression ) (tree rigop $1 $3 )))

        (relational_expression
          ((shift_expression                               ) $1                )
          ((relational_expression LESS shift_expression    ) (tree lesop $1 $3 ))
          ((relational_expression GREATER shift_expression ) (tree greop $1 $3 ))
          ((relational_expression LE_OP shift_expression   ) (tree leqop $1 $3 ))
          ((relational_expression GE_OP shift_expression   ) (tree geqop $1 $3 )))

        (equality_expression 
          ((relational_expression                           ) $1                )
          ((equality_expression EQ_OP relational_expression ) (tree equop $1 $3 ))
          ((equality_expression NE_OP relational_expression ) (tree neqop $1 $3 )))

        (and_expression 
          ((equality_expression                          ) $1                )
          ((and_expression AMPERSAND equality_expression ) (tree ampop $1 $3 )))

        (exclusive_or_expression 
          ((and_expression                               ) $1                )
          ((exclusive_or_expression CARET and_expression ) (tree xorop $1 $3 )))

        (inclusive_or_expression 
          ((exclusive_or_expression                              ) $1                )
          ((inclusive_or_expression PIPE exclusive_or_expression ) (tree pipop $1 $3 )))

        (logical_and_expression 
          ((inclusive_or_expression                               ) $1                )
          ((logical_and_expression AND_OP inclusive_or_expression ) (tree andop $1 $3 )))

        (logical_or_expression 
          ((logical_and_expression                             ) $1                )
          ((logical_or_expression OR_OP logical_and_expression ) (tree or_op $1 $3 )))

        (conditional_expression 
          ((logical_or_expression                                                      ) $1                   )
          ((logical_or_expression QUESTIONMARK expression COLON conditional_expression ) (tree terop $1 $3 $5 )))

        (assignment_expression 
          ((conditional_expression                                     ) $1              )
          ((unary_expression assignment_operator assignment_expression ) (assgn $2 $1 $3 )))

        (assignment_operator
          ((ASSIGN       ) no__op_assgn )
          ((MUL_ASSIGN   ) mul_op_assgn )
          ((DIV_ASSIGN   ) div_op_assgn )
          ((MOD_ASSIGN   ) mod_op_assgn )
          ((ADD_ASSIGN   ) add_op_assgn )
          ((SUB_ASSIGN   ) sub_op_assgn )
          ((LEFT_ASSIGN  ) lef_op_assgn )
          ((RIGHT_ASSIGN ) rig_op_assgn )
          ((AND_ASSIGN   ) and_op_assgn )
          ((XOR_ASSIGN   ) xor_op_assgn )
          ((OR_ASSIGN    ) or__op_assgn ))

        (expression 
          ((assignment_expression                  ) $1)
          ((expression COMMA assignment_expression ) (tree expr $1 $3)))

        (constant_expression 
          ((conditional_expression ) #f ))

        (declaration 
          ((declaration_specifiers SEMICOLON                      ) #f )
          ((type_declaration SEMICOLON                            ) #f )
          ((declaration_specifiers init_declarator_list SEMICOLON ) (tree decl $1 $2)))


        (declaration_specifiers
          ((storage_class_specifier                                 ) #f )
          ((storage_class_specifier declaration_specifiers          ) #f )
          ((type_specifier                                          ) $1 )
          ((type_specifier declaration_specifiers                   ) #f )
          ((type_qualifier                                          ) #f )
          ((type_qualifier declaration_specifiers                   ) #f )
          ((declspec storage_class_specifier                        ) #f )
          ((declspec storage_class_specifier declaration_specifiers ) #f )
          ((declspec type_specifier                                 ) #f )
          ((declspec type_specifier declaration_specifiers          ) #f )
          ((declspec type_qualifier                                 ) #f )
          ((declspec type_qualifier declaration_specifiers          ) #f ))

        (init_declarator_list 
          ((init_declarator                            ) $1 )
          ((init_declarator_list COMMA init_declarator ) (list (append (car $1) (car $3)) (append (cadr $1) (cadr $3)))))

        (init_declarator 
          ((declarator                    ) (list (list $1) (list (list skip))))
          ((declarator ASSIGN initializer ) (list (list $1) (list (assgn no__op_assgn (list identf (cadr $1)) $3)))))

        (declspec_type 
          ((DLLIMPORT ) #f )
          ((DLLEXPORT ) #f ))

        (declspec 
          ((DECLSPEC LB declspec_type RB ) #f ))

        (storage_class_specifier 
          ((EXTERN   ) #f )
          ((STATIC   ) #f )
          ((AUTO     ) #f )
          ((REGISTER ) #f ))

        (type_declarator 
          ((pointer type_direct_declarator ) #f )
          ((type_direct_declarator         ) #f ))

        (type_direct_declarator
          ((identifier                                         ) #f )
          ((LB type_declarator RB                              ) #f )
          ((type_direct_declarator LSB constant_expression RSB ) #f )
          ((type_direct_declarator LSB RSB                     ) #f )
          ((type_direct_declarator LB parameter_type_list RB   ) #f )
          ((type_direct_declarator LB identifier_list RB       ) #f )
          ((type_direct_declarator LB RB                       ) #f ))

        (type_declaration 
          ((TYPEDEF declaration_specifiers type_declarator ) #f ))

        (type_specifier
          ((VOID                      ) voitype )
          ((CHAR                      ) chatype )
          ((SHORT                     ) shotype )
          ((INT                       ) inttype )
          ((LONG                      ) lontype )
          ((FLOAT                     ) flotype )
          ((DOUBLE                    ) doutype )
          ((SIGNED                    ) sigtype )
          ((UNSIGNED                  ) unstype )
          ((struct_or_union_specifier ) #f      )
          ((enum_specifier            ) #f      ))

        (struct_or_union_specifier 
          ((struct_or_union identifier LCB struct_declaration_list RCB ) #f )
          ((struct_or_union LCB struct_declaration_list RCB            ) #f )
          ((struct_or_union identifier                                 ) #f ))

        (struct_or_union 
          ((STRUCT ) #f )
          ((UNION  ) #f ))

        (struct_declaration_list 
          ((struct_declaration                         ) #f )
          ((struct_declaration_list struct_declaration ) #f ))

        (struct_declaration 
          ((specifier_qualifier_list struct_declarator_list SEMICOLON ) #f ))

        (specifier_qualifier_list 
          ((type_specifier specifier_qualifier_list ) #f )
          ((type_specifier                          ) $1 )
          ((type_qualifier specifier_qualifier_list ) #f )
          ((type_qualifier                          ) #f ))

        (struct_declarator_list 
          ((struct_declarator                              ) #f )
          ((struct_declarator_list COMMA struct_declarator ) #f ))

        (struct_declarator 
          ((declarator                           ) #f )
          ((COLON constant_expression            ) #f )
          ((declarator COLON constant_expression ) #f ))

        (enum_specifier 
          ((ENUM LCB enumerator_list RCB            ) #f )
          ((ENUM identifier LCB enumerator_list RCB ) #f )
          ((ENUM identifier                         ) #f ))

        (enumerator_list 
          ((enumerator                       ) #f )
          ((enumerator_list COMMA enumerator ) #f ))

        (enumerator 
          ((identifier                            ) #f )
          ((identifier ASSIGN constant_expression ) #f ))

        (type_qualifier 
          ((CONST    ) #f )
          ((VOLATILE ) #f ))

        (declarator 
          ((pointer direct_declarator ) #f )
          ((direct_declarator         ) $1 ))

        (direct_declarator
          ((identifier                                    ) (list var_ $1       ))
          ((LB declarator RB                              ) #f                  )
          ((direct_declarator LSB constant_expression RSB ) #f                  )
          ((direct_declarator LSB RSB                     ) #f                  )
          ((direct_declarator LB parameter_type_list RB   ) (list func (cadr $1 ) $3   ))
          ((direct_declarator LB identifier_list RB       ) #f                  )
          ((direct_declarator LB RB                       ) (list func (cadr $1 ) null )))

        (pointer 
          ((ASTERISK                             ) #f )
          ((ASTERISK type_qualifier_list         ) #f )
          ((ASTERISK pointer                     ) #f )
          ((ASTERISK type_qualifier_list pointer ) #f ))

        (type_qualifier_list 
          ((type_qualifier                     ) #f )
          ((type_qualifier_list type_qualifier ) #f ))

        (parameter_type_list 
          ((parameter_list                ) $1 )
          ((parameter_list COMMA ELLIPSIS ) #f ))

        (parameter_list 
          ((parameter_declaration                      ) (list $1))
          ((parameter_list COMMA parameter_declaration ) (append $1 (list $3))))

        (parameter_declaration 
          ((declaration_specifiers declarator          ) (list $1 $2))
          ((declaration_specifiers abstract_declarator ) #f )
          ((declaration_specifiers                     ) #f ))

        (identifier_list 
          ((identifier                       ) (list $1))
          ((identifier_list COMMA identifier ) (append $1 (list $3))))

        (type_name 
          ((specifier_qualifier_list                     ) $1 )
          ((specifier_qualifier_list abstract_declarator ) #f ))

        (abstract_declarator 
          ((pointer                            ) #f )
          ((direct_abstract_declarator         ) #f )
          ((pointer direct_abstract_declarator ) #f ))

        (direct_abstract_declarator
          ((LB abstract_declarator RB                              ) #f )
          ((LSB RSB                                                ) #f )
          ((LSB constant_expression RSB                            ) #f )
          ((direct_abstract_declarator LSB RSB                     ) #f )
          ((direct_abstract_declarator LSB constant_expression RSB ) #f )
          ((LB RB                                                  ) #f )
          ((LB parameter_type_list RB                              ) #f )
          ((direct_abstract_declarator LB RB                       ) #f )
          ((direct_abstract_declarator LB parameter_type_list RB   ) #f ))

        (initializer 
          ((assignment_expression          ) $1 )
          ((LCB initializer_list RCB       ) #f )
          ((LCB initializer_list COMMA RCB ) #f ))

        (initializer_list 
          ((initializer                        ) #f )
          ((initializer_list COMMA initializer ) #f ))

        (statement 
          ((labeled_statement    ) #f )
          ((compound_statement   ) $1 )
          ((expression_statement ) $1 )
          ((selection_statement  ) $1 )
          ((iteration_statement  ) $1 )
          ((jump_statement       ) $1 ))

        (labeled_statement 
          ((identifier COLON statement               ) #f )
          ((CASE constant_expression COLON statement ) #f )
          ((DEFAULT COLON statement                  ) #f ))

        (compound_statement 
          ((LCB RCB                                 ) (list (list skip)))
          ((LCB statement_list RCB                  ) $2 )
          ((LCB declaration_list RCB                ) $2 )
          ((LCB declaration_list statement_list RCB ) (append $2 $3)))

        (declaration_list 
          ((declaration                  ) (list $1))
          ((declaration_list declaration ) (append $1 (list $2))))

        (statement_list 
          ((statement                ) $1            )
          ((statement_list statement ) (append $1 $2 )))

        (expression_statement 
          ((SEMICOLON            ) (list (list skip) ))
          ((expression SEMICOLON ) (list $1   )))

        (selection_statement 
          ((IF LB expression RB statement                ) (list (tree 'if_stmt $3 $5 (list (list skip) ))))
          ((IF LB expression RB statement ELSE statement ) (list (tree 'if_stmt $3 $5 $7         )))
          ((SWITCH LB expression RB statement            ) #f                                    ))

        (iteration_statement
          ((WHILE LB expression RB statement                                         ) (list (tree 'while_stmt $3 $5               )))
          ((DO statement WHILE LB expression RB SEMICOLON                            ) #f                                          )
          ((FOR LB expression_statement expression_statement RB statement            ) (list (tree 'for_stmt $3 $4 (list (list skip)) $6 )))
          ((FOR LB expression_statement expression_statement expression RB statement ) (list (tree 'for_stmt $3 $4 $5 $7           ))))

        (jump_statement 
          ((GOTO identifier SEMICOLON   ) #f )
          ((CONTINUE SEMICOLON          ) (list (list 'continue)))
          ((BREAK SEMICOLON             ) (list (list 'break)))
          ((RETURN SEMICOLON            ) (list (list return)))
          ((RETURN expression SEMICOLON ) (list (list return $2))))

        (translation_unit 
          ((external_declaration                  ) $1 )
          ((translation_unit external_declaration ) (append $1 $2 )))

        (external_declaration
          ((function_definition     ) (list $1 ))
          ((declaration             ) (list $1 ))
          ((class_interface         ) #f       )
          ((class_implementation    ) #f       )
          ((category_interface      ) #f       )
          ((category_implementation ) #f       )
          ((protocol_declaration    ) #f       )
          ((class_declaration_list  ) #f       ))

        (function_definition
          ((declaration_specifiers declarator declaration_list compound_statement ) #f                  )
          ((declaration_specifiers declarator compound_statement                  ) (tree defi $1 $2 $3 ))
          ((declarator declaration_list compound_statement                        ) #f                  )
          ((declarator compound_statement                                         ) #f                  ))

        (class_interface
          ((INTERFACE class_name instance_variables interface_declaration_list END                                               ) #f )
          ((INTERFACE class_name COLON superclass_name instance_variables interface_declaration_list END                         ) #f )
          ((INTERFACE protocol_reference_list instance_variables interface_declaration_list END                                  ) #f )
          ((INTERFACE class_name COLON superclass_name protocol_reference_list instance_variables interface_declaration_list END ) #f ))

        (class_implementation
          ((IMPLEMENTATION class_name instance_variables implementation_definition_list END                       ) #f )
          ((IMPLEMENTATION class_name COLON superclass_name instance_variables implementation_definition_list END ) #f ))

        (category_interface
          ((INTERFACE class_name LB category_name RB interface_declaration_list END                         ) #f )
          ((INTERFACE class_name LB category_name RB protocol_reference_list interface_declaration_list END ) #f ))

        (category_implementation 
          ((IMPLEMENTATION class_name LB category_name RB implementation_definition_list END ) #f ))

        (protocol_declaration 
          ((PROTOCOL protocol_name interface_declaration_list END                         ) #f )
          ((PROTOCOL protocol_name protocol_reference_list interface_declaration_list END ) #f ))

        (class_declaration_list 
          ((CLASS class_list ) #f ))

        (class_list 
          ((class_name                  ) #f )
          ((class_list COMMA class_name ) #f ))

        (protocol_reference_list 
          ((LESS protocol_list GREATER ) #f ))

        (protocol_list 
          ((protocol_name                     ) #f )
          ((protocol_list COMMA protocol_name ) #f ))

        (class_name 
          ((identifier ) #f ))

        (superclass_name 
          ((identifier ) #f ))

        (category_name 
          ((identifier ) #f ))

        (protocol_name 
          ((identifier ) #f ))

        (instance_variables
          ((LCB struct_declaration_list RCB                                             ) #f )
          ((LCB visibility_specification struct_declaration_list RCB                    ) #f )
          ((LCB struct_declaration_list instance_variables RCB                          ) #f )
          ((LCB visibility_specification struct_declaration_list instance_variables RCB ) #f ))

        (visibility_specification 
          ((PRIVATE   ) #f )
          ((PUBLIC    ) #f )
          ((PROTECTED ) #f ))

        (interface_declaration_list 
          ((declaration                                   ) #f )
          ((method_declaration                            ) #f )
          ((interface_declaration_list declaration        ) #f )
          ((interface_declaration_list method_declaration ) #f ))

        (method_declaration 
          ((class_method_declaration    ) #f )
          ((instance_method_declaration ) #f ))

        (class_method_declaration 
          ((PLUS method_selector SEMICOLON             ) #f )
          ((PLUS method_type method_selector SEMICOLON ) #f ))

        (instance_method_declaration 
          ((MINUS method_selector SEMICOLON             ) #f )
          ((MINUS method_type method_selector SEMICOLON ) #f ))

        (implementation_definition_list
          ((function_definition                                ) #f )
          ((declaration                                        ) #f )
          ((method_definition                                  ) #f )
          ((implementation_definition_list function_definition ) #f )
          ((implementation_definition_list declaration         ) #f )
          ((implementation_definition_list method_definition   ) #f ))

        (method_definition 
          ((class_method_definition    ) #f )
          ((instance_method_definition ) #f ))

        (class_method_definition
          ((PLUS method_selector compound_statement                              ) #f )
          ((PLUS method_type method_selector compound_statement                  ) #f )
          ((PLUS method_selector declaration_list compound_statement             ) #f )
          ((PLUS method_type method_selector declaration_list compound_statement ) #f ))

        (instance_method_definition
          ((MINUS method_selector compound_statement                              ) #f )
          ((MINUS method_type method_selector compound_statement                  ) #f )
          ((MINUS method_selector declaration_list compound_statement             ) #f )
          ((MINUS method_type method_selector declaration_list compound_statement ) #f ))

        (method_selector 
          ((unary_selector                             ) #f )
          ((keyword_selector                           ) #f )
          ((keyword_selector COMMA ELLIPSIS            ) #f )
          ((keyword_selector COMMA parameter_type_list ) #f ))

        (unary_selector 
          ((selector ) #f ))

        (keyword_selector 
          ((keyword_declarator                  ) #f )
          ((keyword_selector keyword_declarator ) #f ))

        (keyword_declarator 
          ((COLON identifier                      ) #f )
          ((COLON method_type identifier          ) #f )
          ((selector COLON identifier             ) #f )
          ((selector COLON method_type identifier ) #f ))

        (selector 
          ((identifier ) #f ))

        (identifier
          ((IDENTIFIER ) $1 ))

        (method_type 
          ((LB type_name RB ) #f ))))))
