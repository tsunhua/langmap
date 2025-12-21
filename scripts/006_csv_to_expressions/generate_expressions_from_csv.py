#!/usr/bin/env python3
"""
通用脚本，用于根据命令行参数将CSV文件转换为SQL插入语句。

该脚本允许通过命令行参数指定：
- CSV文件路径
- 表达式的状态(review_status)
- 表达式的创建者(created_by)
- 输出SQL文件路径
- 收藏集ID（可选）
- 参考表达式语言列（默认为 en_US）
- 以及其他元数据
"""

import csv
import json
import argparse
from datetime import datetime
import sys
import os


def stable_hash_id(content: str) -> int:
    """
    使用FNV-1a 32位哈希算法基于内容生成稳定ID。
    这确保相同的内容总是产生相同的ID。
    
    Args:
        content: 要哈希的字符串内容
        
    Returns:
        从内容哈希派生的稳定整数ID
    """
    # 使用FNV-1a 32位算法
    h = 0x811c9dc5  # FNV偏移基准
    for char in content:
        h ^= ord(char)
        h = (h * 0x01000193) & 0xFFFFFFFF  # FNV素数并限制为32位
    # 确保我们不会得到0作为ID（最小ID应该是1）
    return (h % (2**31 - 1)) + 1


def escape_sql_string(value):
    """
    转义SQL字符串中的单引号。
    
    Args:
        value: 要转义的字符串值
        
    Returns:
        转义后的字符串
    """
    if value is None:
        return 'NULL'
    return "'" + str(value).replace("'", "''") + "'"


def parse_tags(tag_string):
    """
    解析标签字符串，将"A|B"格式转换为标签列表。
    
    Args:
        tag_string: 标签字符串，格式为"A|B"
        
    Returns:
        标签列表
    """
    if not tag_string or not tag_string.strip():
        return []
    return [tag.strip() for tag in tag_string.split('|') if tag.strip()]


def merge_tags(global_tags, local_tags):
    """
    合并全局标签和本地标签。
    
    Args:
        global_tags: 全局标签列表
        local_tags: 本地标签列表
        
    Returns:
        合并后的标签列表
    """
    merged = list(global_tags)  # 复制全局标签
    for tag in local_tags:
        if tag not in merged:
            merged.append(tag)
    return merged


def generate_values_tuple(expression_id, text, language_code, source_type, review_status, 
                         created_by, source_ref, tags, meaning_id=None):
    """
    为表达式表生成SQL VALUES元组。
    
    Args:
        expression_id: 从stable_hash_id生成的表达式ID
        text: 表达式文本
        language_code: 语言代码
        source_type: 来源类型
        review_status: 审核状态
        created_by: 创建者
        source_ref: 来源参考
        tags: 标签数组
        meaning_id: 关联的参考表达式ID
        
    Returns:
        SQL VALUES元组字符串
    """
    # 基本字段
    values = [
        str(expression_id),
        escape_sql_string(text),
        escape_sql_string(language_code),
    ]
    
    # 处理source_type字段 - 如果为空则使用NULL
    if source_type:
        values.append(escape_sql_string(source_type))
    else:
        values.append('NULL')
        
    values.append(escape_sql_string(review_status))
    values.append(escape_sql_string(created_by))
    
    # 处理source_ref字段 - 如果为空则使用NULL
    if source_ref:
        values.append(escape_sql_string(source_ref))
    else:
        values.append('NULL')
    
    # 处理标签字段 - 如果标签为空则使用NULL，否则使用JSON格式
    if tags:
        values.append(escape_sql_string(json.dumps(tags, ensure_ascii=False)))
    else:
        values.append('NULL')
    
    # 如果提供了meaning_id则添加
    if meaning_id:
        values.append(str(meaning_id))
    else:
        values.append('NULL')
    
    # 添加时间戳字段
    timestamp = datetime.utcnow().strftime('%Y-%m-%d %H:%M:%S')
    values.append(f"'{timestamp}'")  # created_at
    
    # 生成VALUES元组
    return f"({', '.join(values)})"


def generate_collection_item_tuple(collection_id, expression_id):
    """
    为collection_items表生成SQL VALUES元组。
    
    Args:
        collection_id: 收藏集ID
        expression_id: 表达式ID
        
    Returns:
        SQL VALUES元组字符串
    """
    timestamp = datetime.utcnow().strftime('%Y-%m-%d %H:%M:%S')
    values = [
        str(collection_id),
        str(expression_id),
        'NULL',  # note
        f"'{timestamp}'"  # created_at
    ]
    return f"({', '.join(values)})"


def split_text_by_pipe(text):
    """
    将包含"|"分隔符的文本拆分为多个表达式。
    
    Args:
        text: 可能包含"|"分隔符的文本
        
    Returns:
        表达式列表
    """
    if '|' in text:
        # 拆分并去除空白
        parts = [part.strip() for part in text.split('|')]
        # 过滤掉空的部分
        return [part for part in parts if part]
    else:
        return [text]


def main():
    """主函数，处理CSV并生成SQL。"""
    parser = argparse.ArgumentParser(description='将CSV文件转换为SQL插入语句')
    parser.add_argument('csv_file', help='输入CSV文件的路径')
    parser.add_argument('-o', '--output', help='输出SQL文件路径', default='expressions.sql')
    parser.add_argument('--status', help='表达式审核状态', default='approved')
    parser.add_argument('--creator', help='表达式创建者', default='system')
    parser.add_argument('--reference-column', help='参考表达式语言列（用于设置meaning_id）', default='en_US')
    
    args = parser.parse_args()
    
    print(f"处理CSV文件: {args.csv_file}")
    
    # 检查输入文件是否存在
    if not os.path.exists(args.csv_file):
        print(f"错误: 输入文件 '{args.csv_file}' 不存在")
        sys.exit(1)
    
    
    # 验证参考列是否存在于CSV中（稍后验证）
    
    # 读取CSV文件
    with open(args.csv_file, 'r', encoding='utf-8') as csvfile:
        # 使用第一行作为字段名
        reader = csv.DictReader(csvfile)
        headers = reader.fieldnames
        
        if not headers:
            print("错误: CSV文件没有标题行")
            sys.exit(1)
        
        # 验证参考列是否存在于CSV中
        if args.reference_column not in headers:
            print(f"警告: 参考列 '{args.reference_column}' 在CSV中不存在")
            print(f"可用的列: {', '.join(headers)}")
            # 不退出，继续处理但不设置meaning_id
        
        print(f"发现语言列: {headers}")
        
        # 打开输出SQL文件
        with open(args.output, 'w', encoding='utf-8') as sqlfile:
            # 写入SQL头部
            sqlfile.write("-- Generated SQL INSERT statements for expressions table\n")
            sqlfile.write(f"-- Generated on: {datetime.now().isoformat()}\n")
            sqlfile.write(f"-- Source file: {args.csv_file}\n")
            sqlfile.write(f"-- Status: {args.status}\n")
            sqlfile.write(f"-- Creator: {args.creator}\n")
            sqlfile.write(f"-- Reference column: {args.reference_column}\n")
            sqlfile.write("\n")
            
            count = 0
            reference_expressions = {}  # 存储参考表达式及其ID
            batch_values = []
            collection_batch_values = []
            batch_size = 500
            base_fields = "id, text, language_code, source_type, review_status, created_by, source_ref, tags, meaning_id, created_at"
            collection_fields = "collection_id, expression_id, note, created_at"
            
            # 第一遍：处理参考表达式
            csvfile.seek(0)  # 重置文件指针
            next(reader)  # 跳过标题
            
            for row in reader:
                if args.reference_column in row and row[args.reference_column].strip():
                    # 拆分参考语言表达式（如果包含"|"）
                    reference_texts = split_text_by_pipe(row[args.reference_column].strip())
                    
                    for ref_text in reference_texts:
                        if ref_text:  # 确保文本不为空
                            count += 1
                            # 获取参考语言的标签（如果存在）
                            reference_tags_col = f"{args.reference_column}_tags"
                            local_tags = []
                            if reference_tags_col in headers and row[reference_tags_col]:
                                local_tags = parse_tags(row[reference_tags_col])
                            
                            # 合并全局标签和本地标签（这里全局标签为空，仅为保持函数一致性）
                            expression_tags = merge_tags([], local_tags)
                            
                            # 获取参考语言的source_ref（如果存在）
                            reference_source_ref_col = f"{args.reference_column}_source_ref"
                            expression_source_ref = None  # 默认为None
                            if reference_source_ref_col in headers and row[reference_source_ref_col]:
                                expression_source_ref = row[reference_source_ref_col]
                            
                            # 获取参考语言的source_type（如果存在）
                            reference_source_type_col = f"{args.reference_column}_source_type"
                            expression_source_type = None  # 默认为None
                            if reference_source_type_col in headers and row[reference_source_type_col]:
                                expression_source_type = row[reference_source_type_col]
                            
                            # 获取参考语言的collection_id（如果存在）
                            reference_collection_id_col = f"{args.reference_column}_collection_id"
                            reference_collection_ids = []
                            if reference_collection_id_col in headers and row[reference_collection_id_col]:
                                collection_id_str = row[reference_collection_id_col]
                                # 支持逗号分隔的多个收藏集ID
                                reference_collection_ids = [int(cid.strip()) for cid in collection_id_str.split(',') if cid.strip().isdigit()]
                            
                            # 为参考语言生成值元组
                            reference_text = ref_text
                            expression_id = stable_hash_id(reference_text)
                            values_tuple = generate_values_tuple(
                                expression_id,
                                reference_text,
                                args.reference_column.replace('_', '-'),  # 转换为标准语言代码格式
                                expression_source_type,
                                args.status,
                                args.creator,
                                expression_source_ref,
                                expression_tags
                            )
                            batch_values.append(values_tuple)
                            
                            # 为参考语言添加到特定收藏集（如果指定了语言特定的收藏集ID）
                            for collection_id in reference_collection_ids:
                                collection_tuple = generate_collection_item_tuple(
                                    collection_id,
                                    expression_id
                                )
                                collection_batch_values.append(collection_tuple)
                            
                            # 如果达到批处理大小则写入批次
                            if len(batch_values) >= batch_size:
                                sqlfile.write(f"INSERT OR IGNORE INTO expressions ({base_fields}) VALUES\n")
                                sqlfile.write(',\n'.join(batch_values) + ';\n\n')
                                batch_values = []
                                
                                # 如果需要添加到收藏集
                                if collection_batch_values:
                                    sqlfile.write(f"INSERT OR IGNORE INTO collection_items ({collection_fields}) VALUES\n")
                                    sqlfile.write(',\n'.join(collection_batch_values) + ';\n\n')
                                    collection_batch_values = []
                                
                                print(f"已写入 {count} 个 {args.reference_column} 表达式...")
                            
                            # 存储ID和文本以供参考
                            reference_expressions[reference_text] = expression_id
            
            # 写入剩余的参考语言语句
            if batch_values:
                sqlfile.write(f"INSERT OR IGNORE INTO expressions ({base_fields}) VALUES\n")
                sqlfile.write(',\n'.join(batch_values) + ';\n\n')
                batch_values = []
                
                # 如果需要添加到收藏集
                if collection_batch_values:
                    sqlfile.write(f"INSERT OR IGNORE INTO collection_items ({collection_fields}) VALUES\n")
                    sqlfile.write(',\n'.join(collection_batch_values) + ';\n\n')
                    collection_batch_values = []
            
            print(f"处理了 {count} 个 {args.reference_column} 表达式")
            
            # 第二遍：处理所有语言
            csvfile.seek(0)  # 重置文件指针
            next(reader)  # 跳过标题
            total_count = count
            
            for row_num, row in enumerate(reader, start=2):  # 从第2行开始计数（因为第1行是标题）
                # 处理每种语言
                for lang_code in headers:
                    # 跳过参考语言列，因为我们已经处理过了
                    # 也跳过标签列、source_ref列、source_type列和collection_id列
                    if (lang_code == args.reference_column or 
                        lang_code.endswith('_tags') or 
                        lang_code.endswith('_source_ref') or
                        lang_code.endswith('_source_type') or
                        lang_code.endswith('_collection_id')):
                        continue
                    
                    text = row[lang_code].strip() if row[lang_code] else ''
                    if text:
                        # 拆分表达式（如果包含"|"）
                        expressions = split_text_by_pipe(text)
                        
                        for expr_text in expressions:
                            if expr_text:  # 确保文本不为空
                                total_count += 1
                                
                                # 查找关联的参考表达式ID
                                meaning_id = None
                                # 使用原始文本查找参考表达式
                                original_ref_text = row[args.reference_column].strip() if args.reference_column in row else ''
                                if original_ref_text and original_ref_text in reference_expressions:
                                    meaning_id = reference_expressions[original_ref_text]
                                # 如果原始文本不在，尝试使用拆分后的任一文本
                                elif original_ref_text:
                                    ref_parts = split_text_by_pipe(original_ref_text)
                                    for ref_part in ref_parts:
                                        if ref_part in reference_expressions:
                                            meaning_id = reference_expressions[ref_part]
                                            break
                                
                                # 获取该语言的标签（如果存在）
                                tags_col = f"{lang_code}_tags"
                                local_tags = []
                                if tags_col in headers and row[tags_col]:
                                    local_tags = parse_tags(row[tags_col])
                                
                                # 合并全局标签和本地标签（这里全局标签为空，仅为保持函数一致性）
                                expression_tags = merge_tags([], local_tags)
                                
                                # 获取该语言的source_ref（如果存在）
                                source_ref_col = f"{lang_code}_source_ref"
                                expression_source_ref = None  # 默认为None
                                if source_ref_col in headers and row[source_ref_col]:
                                    expression_source_ref = row[source_ref_col]
                                
                                # 获取该语言的source_type（如果存在）
                                source_type_col = f"{lang_code}_source_type"
                                expression_source_type = None  # 默认为None
                                if source_type_col in headers and row[source_type_col]:
                                    expression_source_type = row[source_type_col]
                                
                                # 获取该语言的collection_id（如果存在）
                                collection_id_col = f"{lang_code}_collection_id"
                                language_collection_ids = []
                                if collection_id_col in headers and row[collection_id_col]:
                                    collection_id_str = row[collection_id_col]
                                    # 支持逗号分隔的多个收藏集ID
                                    language_collection_ids = [int(cid.strip()) for cid in collection_id_str.split(',') if cid.strip().isdigit()]
                                
                                # 生成表达式ID
                                expression_id = stable_hash_id(expr_text+"|"+lang_code)
                                
                                # 生成值元组
                                # 将下划线格式转换为连字符格式（标准语言代码格式）
                                formatted_lang_code = lang_code.replace('_', '-')
                                values_tuple = generate_values_tuple(
                                    expression_id,
                                    expr_text,
                                    formatted_lang_code,
                                    expression_source_type,
                                    args.status,
                                    args.creator,
                                    expression_source_ref,
                                    expression_tags,
                                    meaning_id=meaning_id,
                                )
                                batch_values.append(values_tuple)
                                
                                # 为该语言添加到特定收藏集（如果指定了语言特定的收藏集ID）
                                for collection_id in language_collection_ids:
                                    collection_tuple = generate_collection_item_tuple(
                                        collection_id,
                                        expression_id
                                    )
                                    collection_batch_values.append(collection_tuple)
                                
                                # 如果达到批处理大小则写入批次
                                if len(batch_values) >= batch_size:
                                    sqlfile.write(f"INSERT OR IGNORE INTO expressions ({base_fields}) VALUES\n")
                                    sqlfile.write(',\n'.join(batch_values) + ';\n\n')
                                    batch_values = []
                                    
                                    # 如果需要添加到收藏集
                                    if collection_batch_values:
                                        sqlfile.write(f"INSERT OR IGNORE INTO collection_items ({collection_fields}) VALUES\n")
                                        sqlfile.write(',\n'.join(collection_batch_values) + ';\n\n')
                                        collection_batch_values = []
                                    
                                    print(f"已写入 {total_count} 个总表达式...")
            
            # 写入剩余语句
            if batch_values:
                sqlfile.write(f"INSERT OR IGNORE INTO expressions ({base_fields}) VALUES\n")
                sqlfile.write(',\n'.join(batch_values) + ';\n\n')
                batch_values = []
                
                # 如果需要添加到收藏集
                if collection_batch_values:
                    sqlfile.write(f"INSERT OR IGNORE INTO collection_items ({collection_fields}) VALUES\n")
                    sqlfile.write(',\n'.join(collection_batch_values) + ';\n\n')
                    collection_batch_values = []
            
            print(f"生成了 {total_count} 个INSERT语句")
            print(f"输出写入到 {args.output}")


if __name__ == "__main__":
    main()