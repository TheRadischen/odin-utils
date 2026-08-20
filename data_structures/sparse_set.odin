package sia

import "core:slice"

// odin implementation of https://github.com/johnBuffer/StableIndexVector/blob/main/index_vector.hpp

Sia :: struct($T: typeid) {
    data_index : [dynamic]int,
    ids : [dynamic]int,
    data : [dynamic]T,
}

insert_sia :: proc(sia: ^Sia($E), data: E) -> int {
    num_data := len(sia.data)
    append(&sia.data, data)
    if len(sia.ids) <= num_data {
        append(&sia.ids, len(sia.ids))
        append(&sia.data_index, len(sia.data_index))
        return num_data
    }
    return sia.ids[num_data]
}
access_sia :: proc(sia: Sia($E), id: int) -> ^E{
    if sia.data_index[id] >= len(sia.data) {
        //("accessing nonexisting data")
        return nil
    }
    return &sia.data[sia.data_index[id]]
}
delete_sia :: proc(sia: ^Sia($E), id: int){
    if sia.data_index[id] >= len(sia.data) {
        //("deleting nonexisting data")
        return
    }
    last := len(sia.data) - 1
    last_id := sia.ids[last]
    cur_id := sia.ids[sia.data_index[id]]
    unordered_remove(&sia.data, sia.data_index[id])
    slice.swap(sia.ids[:],last, sia.data_index[id])
    slice.swap(sia.data_index[:],last_id,cur_id)
}

delete_sia_data_index :: proc(sia: ^Sia($E), index: int) {
    delete_sia(sia, sia.ids[index])
}
