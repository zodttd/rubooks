/* -*- mode: c; indent-tabs-mode: nil; -*-
 * $Id: util.c,v 1.5 2005-04-05 14:25:56 chrish Exp $
 *
 * util -- Some simple utility routines so we don't need GLib
 * Copyright (c) 2002, Bill Janssen
 * 
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License
 * as published by the Free Software Foundation; either version 2
 * of the License, or (at your option) any later version.
 * 
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.
 *
 */

#include <stdlib.h>
#include <sys/types.h>
#include <string.h>             /* for strndup() */

#include <zlib.h>

#include "unpluck.h"
#include "unpluckint.h"

/***********************************************************************/
/***********************************************************************/
/*****                                                             *****/
/*****                   String Utilities                          *****/
/*****                                                             *****/
/***********************************************************************/
/***********************************************************************/

char* _plkr_strndup(char* str, int len) {
    char*  dup;

    dup = (char *) malloc (len + 1);
    strncpy (dup, str, len);
    dup[len] = 0;
    return dup;
}

/***********************************************************************/
/***********************************************************************/
/*****                                                             *****/
/*****  Simple hash table maps string keys to void * values        *****/
/*****                                                             *****/
/***********************************************************************/
/***********************************************************************/

typedef struct {
    char*  he_key;
    void*  he_data;
} HashEntry;

typedef struct {
    int         hs_count;
    int         hs_allocated;
    HashEntry*  hs_entries;
} HashTableSlot;

struct HashTable {
    int             ht_size;
    int             ht_nPairs;
    HashTableSlot*  ht_slots;
};

#define HASH_INCREMENT_SIZE	5

#define hashtable_slot(ht,index)             (&((ht)->ht_slots[index]))
#define hashtable_hash_index(ht,key)         (HashString((key), (ht)->ht_size))
#define hashtable_compare_keys(ht,key1,key2) (CompareStrings((key1),(key2)))

static int CompareStrings(char* key1, char* key2) {
    return (strcmp (key1, key2) == 0);
}

static int HashString(char* str, int size) {
    unsigned long  crc;

    crc = crc32 (0L, NULL, 0);
    crc = crc32 (crc, (unsigned char*)str, strlen (str));
    return (crc % size);
}

void* _plkr_FindInTable(HashTable* ht, char* key) {
    HashTableSlot*  slot;
    int             count;

    if (ht == NULL)
        return (NULL);
    slot = hashtable_slot (ht, hashtable_hash_index (ht, key));
    for (count = slot->hs_count; count > 0; count -= 1)
        if (hashtable_compare_keys
            (ht, key, slot->hs_entries[count - 1].he_key))
            return (slot->hs_entries[count - 1].he_data);
    return (NULL);
}

void* _plkr_RemoveFromTable(HashTable* ht, char* key) {
    HashTableSlot*  slot;
    int             count;

    if (ht == NULL)
        return (NULL);

    slot = hashtable_slot (ht, hashtable_hash_index (ht, key));
    for (count = 0; count < slot->hs_count; count += 1)
        if (hashtable_compare_keys
            (ht, slot->hs_entries[count].he_key, key)) {
            void *data = slot->hs_entries[count].he_data;
            free (slot->hs_entries[count].he_key);
            if ((1 + (unsigned) count) < (unsigned) slot->hs_count)
                slot->hs_entries[count] =
                    slot->hs_entries[slot->hs_count - 1];
            --ht->ht_nPairs;
            if (--slot->hs_count <= 0) {
                free (slot->hs_entries);
                slot->hs_entries = NULL;
                slot->hs_allocated = 0;
                slot->hs_count = 0;
            }
            return (data);
        }
    return (NULL);
}

int _plkr_AddToTable(HashTable* ht, char* key, void* obj) {
    HashTableSlot*  slot;
    int             count;

    if (ht == NULL)
        return (0);

    slot = hashtable_slot (ht, hashtable_hash_index (ht, key));

    for (count = slot->hs_count; count > 0; count -= 1) {
        if (hashtable_compare_keys(ht, key, slot->hs_entries[count - 1].he_key)) {
          return (0);
        }
    }

    if (slot->hs_allocated == 0) {
        slot->hs_allocated = HASH_INCREMENT_SIZE;
        slot->hs_entries =
            (HashEntry *) malloc (sizeof (HashEntry) * slot->hs_allocated);
        slot->hs_count = 0;
    }
    else if (slot->hs_count >= slot->hs_allocated)
        slot->hs_entries = (HashEntry *) realloc (slot->hs_entries,
                                                  (slot->hs_allocated +=
                                                   HASH_INCREMENT_SIZE)
                                                  * sizeof (HashEntry));
    slot->hs_entries[slot->hs_count].he_key =
        _plkr_strndup (key, strlen (key));
    slot->hs_entries[slot->hs_count].he_data = obj;
    slot->hs_count += 1;
    ht->ht_nPairs += 1;
    return (1);
}

HashTable* _plkr_NewHashTable(int size) {
    HashTable *new = (HashTable *) malloc (sizeof (HashTable));

    new->ht_size = size;
    new->ht_nPairs = 0;
    new->ht_slots =
        (HashTableSlot *) malloc (sizeof (HashTableSlot) * size);
    memset ((void *) (new->ht_slots), 0, sizeof (HashTableSlot) * size);
    return (new);
}
